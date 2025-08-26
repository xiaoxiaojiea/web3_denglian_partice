import { createWalletClient, createPublicClient, http, formatEther, parseEther } from "viem";
import { privateKeyToAccount, generatePrivateKey } from "viem/accounts";
import { sepolia } from "viem/chains";
import readlineSync from "readline-sync";
import dotenv from "dotenv";
dotenv.config();


// ==== 配置 ====
const RPC_URL = process.env.SEPOLIA_RPC_URL;
const ERC20_ADDRESS = '0x1a1Dd7994A1bA16BD2a58cd076EbeA69266587D6';
const ERC20_ABI = [
    { "constant": true, "inputs": [{ "name": "_owner", "type": "address" }], "name": "balanceOf", "outputs": [{ "name": "balance", "type": "uint256" }], "type": "function" },
    { "constant": false, "inputs": [{ "name": "_to", "type": "address" }, { "name": "_value", "type": "uint256" }], "name": "transfer", "outputs": [{ "name": "", "type": "bool" }], "type": "function" },
    { "constant": true, "inputs": [], "name": "decimals", "outputs": [{ "name": "", "type": "uint8" }], "type": "function" },
    { "constant": true, "inputs": [], "name": "symbol", "outputs": [{ "name": "", "type": "string" }], "type": "function" }
];

// ==== 客户端 ====
let currentAccount = null;  // 存储当前操作的钱包信息（钱包地址，私钥），构建签名交易时用到这个账户的私钥，“切换钱包”时，这个变量会被更新为新的账户对象
let walletClient = null;  // 钱包客户端

// 公共客户端
const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(RPC_URL),
});

// ==== 钱包管理 ====
function createNewWallet() {
    const privateKey = generatePrivateKey(); // 生成随机私钥

    // 记录当前钱包信息（用私钥拿到钱包信息）
    currentAccount = privateKeyToAccount(privateKey); // 根据私钥创建账户
    // 更新钱包客户端
    walletClient = createWalletClient({ account: currentAccount, chain: sepolia, transport: http(RPC_URL) });

    console.log("✅ 新钱包已创建");
    console.log("地址:", currentAccount.address);
    console.log("私钥:", privateKey); // 保存好这个私钥
}

function importWalletByPrivateKey() {
    // 拿到私钥
    const pk = readlineSync.question("请输入私钥: ", { hideEchoBack: true });
    try {
        // 根据私钥拿到钱包信息
        currentAccount = privateKeyToAccount(pk);
        // 更新钱包客户端
        walletClient = createWalletClient({ account: currentAccount, chain: sepolia, transport: http(RPC_URL) });
        console.log("✅ 钱包已切换到:", currentAccount.address);
    } catch (err) {
        console.log("❌ 私钥无效", err);
    }
}

function switchWallet() {
    console.log("\n===== 钱包切换 =====");
    console.log("1. 创建新钱包");
    console.log("2. 输入私钥切换钱包");
    const choice = readlineSync.question("请选择: ");
    if (choice === "1") createNewWallet();
    else if (choice === "2") importWalletByPrivateKey();
}

// ==== 功能 ====
async function getEthBalance() {
    if (!currentAccount) { console.log("❌ 请先切换钱包"); return; }
    // 公开客户端拿到eth余额
    const balance = await publicClient.getBalance({ address: currentAccount.address });
    console.log("ETH 余额:", formatEther(balance), "ETH");
}

async function getErc20Balance() {
    if (!currentAccount) { console.log("❌ 请先切换钱包"); return; }
    // 公开客户端拿到只读ERC20和与信息
    const [decimals, symbol, balance] = await Promise.all([
        publicClient.readContract({ address: ERC20_ADDRESS, abi: ERC20_ABI, functionName: "decimals" }),
        publicClient.readContract({ address: ERC20_ADDRESS, abi: ERC20_ABI, functionName: "symbol" }),
        publicClient.readContract({ address: ERC20_ADDRESS, abi: ERC20_ABI, functionName: "balanceOf", args: [currentAccount.address] }),
    ]);
    console.log(`ERC20 余额: ${Number(balance) / 10 ** decimals} ${symbol}`);
}

async function transferEth() {
    if (!currentAccount) { console.log("❌ 请先切换钱包"); return; }
    const to = readlineSync.question("请输入接收地址: ");
    const amount = readlineSync.question("请输入转账数量(ETH): ");
    try {
        // 私钥客户端发送eth
        const txHash = await walletClient.sendTransaction({
            to,
            value: parseEther(amount),
        });
        console.log("✅ ETH 转账提交成功, hash:", txHash);
    } catch (err) {
        console.log("❌ 转账失败:", err);
    }
}

async function transferErc20() {
    if (!currentAccount) { console.log("❌ 请先切换钱包"); return; }
    const to = readlineSync.question("请输入接收地址: ");
    const amount = readlineSync.question("请输入转账数量(整数): ");

    const decimals = await publicClient.readContract({ address: ERC20_ADDRESS, abi: ERC20_ABI, functionName: "decimals" });
    const value = BigInt(amount) * BigInt(10 ** decimals);

    try {
        // 私钥客户端发送ERC20代币
        const txHash = await walletClient.writeContract({
            address: ERC20_ADDRESS,
            abi: ERC20_ABI,
            functionName: "transfer",
            args: [to, value],
        });
        console.log("✅ ERC20 转账提交成功, hash:", txHash);
    } catch (err) {
        console.log("❌ 转账失败:", err);
    }
}

async function transferErc20EIP1559() {
    if (!currentAccount) { 
        console.log("❌ 请先切换钱包"); 
        return; 
    }

    const to = readlineSync.question("请输入接收地址: ");
    const amount = readlineSync.question("请输入转账数量(整数): ");

    // 获取 ERC20 decimals
    const decimals = await publicClient.readContract({ 
        address: ERC20_ADDRESS, 
        abi: ERC20_ABI, 
        functionName: "decimals" 
    });
    const value = BigInt(amount) * BigInt(10 ** decimals);

    try {
        // 获取当前网络的 baseFeePerGas
        const latestBlock = await publicClient.getBlock({ blockTag: 'latest' });
        const baseFeePerGas = latestBlock.baseFeePerGas || 0n;

        // 设置优先费（小费），可以根据需要调整
        const maxPriorityFeePerGas = 2_000_000_000n; // 2 gwei
        const maxFeePerGas = baseFeePerGas * 2n + maxPriorityFeePerGas; // 安全上限

        const txHash = await walletClient.writeContract({
            address: ERC20_ADDRESS,
            abi: ERC20_ABI,
            functionName: "transfer",
            args: [to, value],
            account: currentAccount,
            // type 2 EIP-1559
            gas: 100_000n, // 估算 ERC20 转账 gas
            maxFeePerGas,
            maxPriorityFeePerGas
        });

        console.log("✅ ERC20 转账提交成功, hash:", txHash);
    } catch (err) {
        console.log("❌ 转账失败:", err);
    }
}

// ==== CLI 菜单 ====
async function mainMenu() {
    while (true) {
        console.log("\n===== CLI 钱包 =====");
        console.log("1. 切换钱包 / 创建钱包");
        console.log("2. 查看 ETH 余额");
        console.log("3. 查看 ERC20 余额");
        console.log("4. 转账 ETH");
        console.log("5. 转账 ERC20");
        console.log("0. 退出");

        const choice = readlineSync.question("请选择功能: ");

        if (choice === "1") switchWallet();
        else if (choice === "2") await getEthBalance();
        else if (choice === "3") await getErc20Balance();
        else if (choice === "4") await transferEth();
        else if (choice === "5") await transferErc20EIP1559();
        else if (choice === "0") process.exit(0);
        else console.log("❌ 请输入有效选项");
    }
}

// ==== 启动 ====
console.log("🚀 欢迎使用 CLI 钱包");
mainMenu();
