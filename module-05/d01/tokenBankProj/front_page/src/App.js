import React, { useState, useEffect } from "react";

import {
  createPublicClient,
  createWalletClient,
  custom,
  http,
  getContract,
  parseEther,
  formatEther,
} from "viem";
import { foundry } from "viem/chains";

// ABI-JSON
import MyToken_JSON from "./abis/MyToken.json" with { type: "json" };
import TokenBank_JSON from "./abis/TokenBank.json" with { type: "json" };

// ABI
const MyToken_ABI = MyToken_JSON.abi;
const TokenBank_ABI = TokenBank_JSON.abi;

// contract
const MyToken_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const TokenBank_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

// 前端 React + viem，使用 MetaMask provider 来和本地 Anvil 节点交互，实现「ERC20 存取款银行」的 DApp。
/**
 * 
 * 
 *  
 */ 

function App() {
    // 状态管理
    const [address, setAddress] = useState(null);  // 当前连接的钱包地址
    const [tokenBalance, setTokenBalance] = useState("0");  // ERC20 余额
    const [bankBalance, setBankBalance] = useState("0");  // 在 TokenBank 的存款余额
    const [amount, setAmount] = useState("");  // 用户输入的操作金额（字符串）
    const [walletClient, setWalletClient] = useState(null);  // 钱包客户端（用来发交易）

    // ==================================================== 公共客户端（只读）
    // 只读 RPC，不需要签名，不依赖钱包, 用于查询余额、存款信息等
    const publicClient = createPublicClient({
        chain: foundry,
        transport: http("http://127.0.0.1:8545"),
    });

    // ==================================================== 连接钱包
    // 用于发起签名连接钱包的函数
    const connectWallet = async () => {
        // 需要使用到metamask注入到网页中的window.ethereum
        if (window.ethereum) {
            // 请求签名
            const accounts = await window.ethereum.request({
                method: "eth_requestAccounts",
            });
            setAddress(accounts[0]);  // 设置当前连接的钱包

            // ================================================ 用 MetaMask provider（会弹出确认）
            // 钱包客户端（用来发交易）
            const client = createWalletClient({
                account: accounts[0],
                chain: foundry,
                transport: custom(window.ethereum), // 改成 custom(window.ethereum) 确认会走metamask确认
            });
            setWalletClient(client);
        } else {
            alert("Please install MetaMask");
        }
    };

    // 查询 ERC20 余额
    const fetchTokenBalance = async () => {
        if (!address) return;

        // 实例化erc20合约对象
        const erc20 = getContract({
            address: MyToken_ADDRESS,
            abi: MyToken_ABI,
            client: publicClient,
        });
        // 查询某个地址余额
        const bal = await erc20.read.balanceOf([address]);
        // 设置余额
        setTokenBalance(formatEther(bal));
    };

    // 查询Bank存款余额
    const fetchBankBalance = async () => {
        if (!address) return;
        // 合约对象
        const bank = getContract({
            address: TokenBank_ADDRESS,
            abi: TokenBank_ABI,
            client: publicClient,
        });
        // 查询
        const bal = await bank.read.balances([address]);
        // 设置
        setBankBalance(formatEther(bal));
    };

    // 刷新页面数据
    const refresh = async () => {
        await fetchTokenBalance();
        await fetchBankBalance();
    };

    // 钩子函数，只要地址存在，则每次刷新页面都需要刷新
    useEffect(() => {
        if (address) refresh();
    }, [address]);

    // 存款
    const handleDeposit = async () => {
        if (!walletClient) return;

        // 初始化erc20合约对象
        const erc20 = getContract({
            address: MyToken_ADDRESS,
            abi: MyToken_ABI,
            client: walletClient,
        });
        // 初始化bank合约对象
        const bank = getContract({
            address: TokenBank_ADDRESS,
            abi: TokenBank_ABI,
            client: walletClient,
        });
        // approve + deposit（需要钱包确认）
        await erc20.write.approve([TokenBank_ADDRESS, parseEther(amount)]);
        await bank.write.deposit([parseEther(amount)]);
        // 刷新页面
        refresh();
    };

    // 取款
    const handleWithdraw = async () => {
        if (!walletClient) return;
        // 实例化合约对象
        const bank = getContract({
            address: TokenBank_ADDRESS,
            abi: TokenBank_ABI,
            client: walletClient,
        });
        // 取款
        await bank.write.withdraw([parseEther(amount)]);
        refresh();
    };

    return (
        <div>
            {!address ? (
                <button onClick={connectWallet}>Connect Wallet</button>
            ) : (
                <div>
                    <h2>Wallet: {address}</h2>
                    <p>Token Balance: {tokenBalance}</p>
                    <p>Bank Deposit: {bankBalance}</p>

                    <input
                        type="text"
                        placeholder="Amount"
                        value={amount}
                        onChange={(e) => setAmount(e.target.value)}
                    />
                    <button onClick={handleDeposit}>Deposit</button>
                    <button onClick={handleWithdraw}>Withdraw</button>
                </div>
            )}
        </div>
    );
}

export default App;
