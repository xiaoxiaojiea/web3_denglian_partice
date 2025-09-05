import { createWalletClient, createPublicClient, http, parseEther } from "viem";
import { privateKeyToAccount } from "viem/accounts";
import { anvil } from "viem/chains";

// ABI-JSON
import Permit2_JSON from "./abis/Permit2.json" with { type: "json" };
import MyToken_JSON from "./abis/MyToken.json" with { type: "json" };
import TokenBank_JSON from "./abis/TokenBank.json" with { type: "json" };

// ABI
const Permit2_ABI = Permit2_JSON.abi;
const MyToken_ABI = MyToken_JSON.abi;
const TokenBank_ABI = TokenBank_JSON.abi;

// contract
const Permit2_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const MyToken_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const TokenBank_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";

const RPC_URL = "http://127.0.0.1:8545";
const PRIVATE_KEY =
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // anvil 第一个账户

// anvil本地链配置，client 用于链上只读请求
const client = createPublicClient({
    chain: anvil,
    transport: http(),
});

// 查找某个地址在 Permit2 下一个未使用的 nonce，这样保证签名不会和之前的冲突
async function getUnusedNonce(owner: `0x${string}`): Promise<bigint> {
    for (let word = 0; word < 10; word++) {
        const bitmap: bigint = await client.readContract({
            address: Permit2_ADDRESS,
            abi: Permit2_ABI,
            functionName: "nonceBitmap",  // Permit2 把 nonce 存在一个 bitmap 中
            args: [owner, BigInt(word)],
        });

        for (let bit = 0; bit < 256; bit++) {
            // 遍历找到某个 bit == 0，就是未使用的 nonce
            if (((bitmap >> BigInt(bit)) & 1n) === 0n) {
                return BigInt(word) * 256n + BigInt(bit);
            }
        }
    }
    throw new Error("未找到可用的 nonce，可能需要扩展搜索范围");
}


// main函数：
/***
 * 目的：用 EIP-712 离线签名 + Permit2 的授权机制，把 MyToken 从用户账户存入 TokenBank 合约。
 *      - 整个流程模拟了 permit 场景（无 gas 的离线授权），然后由 TokenBank 调用 Permit2 完成代币转账。
 * 核心组件：
 *      - Permit2 合约：Uniswap 提出的通用授权合约，统一了 permit 功能（支持 nonce 管理）。
 *      - MyToken 合约：ERC20 测试代币。
 *      - TokenBank 合约：模拟银行，支持 depositWithPermit2 函数，用来通过 Permit2 存款。
 * 总结流程
 *      - 用户 approve(MyToken → Permit2)，让 Permit2 能代为转账。
 *      - 用户 离线签名（EIP-712，包含 token、amount、spender、nonce、deadline）。
 *      - 用户调用 TokenBank.depositWithPermit2(...)，把签名和参数交给银行。
 *      - TokenBank → 调 Permit2 → 检查签名有效 → 转账 MyToken（因为Permit2已有token的最大授权） → 存入银行。
 *      - 最终，用户在 TokenBank 中的余额增加。
 */
async function main() {
    // 创建账户
    const account = privateKeyToAccount(PRIVATE_KEY as `0x${string}`);
    // 创建公开客户端
    const publicClient = createPublicClient({  // publicClient 用来查链上状态、等交易确认
        chain: anvil,
        transport: http(RPC_URL),
    });
    // 创建钱包客户端
    const walletClient = createWalletClient({  // walletClient 用来发交易
        account,
        chain: anvil,
        transport: http(RPC_URL),
    });
    console.log("用户地址:", account.address);

    // step1: 先 approve 给 Permit2（先给 Permit2 无限额度授权，否则它没法代用户转账）
    //      ***这个执行一次就可以了，后续执行可以注释这个***
    console.log("发送 approve 给 Permit2...");
    const approveHash = await walletClient.writeContract({
        address: MyToken_ADDRESS,
        abi: MyToken_ABI,
        functionName: "approve",
        args: [Permit2_ADDRESS, 2n ** 256n - 1n],
    });
    await publicClient.waitForTransactionReceipt({ hash: approveHash });
    console.log("approve 完成 ✅");

    // step2: 构造 permit 参数
    const amount = parseEther("100");  // 转账金额
    const nonce = await getUnusedNonce(account.address);  // 拿到当前账户可用的nonce
    console.log("下一个可用 nonce:", nonce.toString());
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 3600);  // 设置 1 小时后过期

    // EIP-712 的签名参数
    const domain = {  // domain 确认链和验证合约
        name: "Permit2",
        chainId: anvil.id,
        verifyingContract: Permit2_ADDRESS,
    };

    // 定义结构体类型
    const types = {
        PermitTransferFrom: [
            { name: "permitted", type: "TokenPermissions" },
            { name: "spender", type: "address" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" },
        ],
        TokenPermissions: [
            { name: "token", type: "address" },
            { name: "amount", type: "uint256" },
        ],
    };

    // 这里 spender 是 TokenBank，因为它会调用 Permit2 来花费 token。
    const values = {
        permitted: {
            token: MyToken_ADDRESS,
            amount,
        },
        spender: TokenBank_ADDRESS,
        nonce,
        deadline,
    };

    // step3: 生成签名（EIP712）
    console.log("生成离线签名...");
    // 得到 signature，类似离线授权凭证
    const signature = await account.signTypedData({  // 本地私钥直接对 PermitTransferFrom 结构体签名
        domain,
        types,
        primaryType: "PermitTransferFrom",
        message: values,
    });

    // step4: 调用 depositWithPermit2
    console.log("调用 depositWithPermit2...");
    // 用户直接调用 TokenBank
    //      TokenBank 内部会调用 Permit2.verify + transfer，把用户的 100 个 Token 存进来
    const txHash = await walletClient.writeContract({
        address: TokenBank_ADDRESS,
        abi: TokenBank_ABI,
        functionName: "depositWithPermit2",
        args: [amount, nonce, deadline, signature],
    });

    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
    console.log("交易完成 ✅ hash:", receipt.transactionHash);

    // step5: 查询余额
    const bankBalance = await publicClient.readContract({
        address: TokenBank_ADDRESS,
        abi: TokenBank_ABI,
        functionName: "balanceOf",
        args: [account.address],
    });
    console.log("TokenBank 存款余额:", bankBalance.toString());
}

// 调用main函数
main().catch((err) => {
    console.error("运行出错:", err);
    process.exit(1);
});
