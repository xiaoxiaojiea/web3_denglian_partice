import { useState, useEffect } from "react";
import "./App.css";
import { createPublicClient, createWalletClient, custom, http } from "viem";
import { sepolia } from "viem/chains";
import EthereumProvider from "@walletconnect/ethereum-provider";

// 导入 ABI
import MyNFTABI from "./abis/MyNFT.json";
import MyTokenABI from "./abis/MyToken.json";
import NFTMarketABI from "./abis/NFTMarket.json";

// 合约部署地址
const CONTRACTS = {
    MyNFT: "0x9Fe64984744be783d40Bb01662e845b8544Ff474",
    MyToken: "0x48aB4cdd2bE0F059efE71c410F08216D3b656892",
    NFTMarket: "0x56D9937BB622Ce9DaA00dC24F9374D332B9136EE",
};

function App() {
    const [account, setAccount] = useState(null);
    const [myNFTs, setMyNFTs] = useState([]);
    const [nftCount, setNftCount] = useState(0);
    const [mintTo, setMintTo] = useState(""); // 输入的接收地址
    const [listNFT, setListNFT] = useState({ nftAddress: "", tokenId: "", price: "" });
    const [buyNFTInput, setBuyNFTInput] = useState({ nftAddress: "", tokenId: "" });
    const [walletClient, setWalletClient] = useState(null);

    // viem client
    const publicClient = createPublicClient({
        chain: sepolia,
        transport: http("https://sepolia.infura.io/v3/xxxxx"),
    });

    async function connectWallet() {
        if (window.ethereum) {
            const walletClient = createWalletClient({
                chain: sepolia,
                transport: custom(window.ethereum),
            });

            const accounts = await walletClient.requestAddresses();
            setAccount(accounts[0]);
        } else {
            alert("请安装 MetaMask！");
        }

        // const provider = await EthereumProvider.init({
        //     projectId: "xxxxx",
        //     chains: [56], // BSC链ID
        //     showQrModal: true,
        // });
    
        // await provider.enable();
    
        // const client = createWalletClient({
        //     chain: sepolia,
        //     transport: custom(provider),
        //   });
    
        //   setWalletClient(client);
    
        //   const accounts = await client.getAddresses();
        //   setAccount(accounts[0]);

    }

    // 获取账号下的NFT数量
    async function fetchMyNFTs() {
        if (!account) return;

        try {
            // 读取 NFT 数量
            const balance = await publicClient.readContract({
                address: CONTRACTS.MyNFT,
                abi: MyNFTABI.abi,
                functionName: "balanceOf",
                args: [account],
            });

            // 更新状态
            setNftCount(Number(balance));
        } catch (err) {
            console.error("获取NFT数量失败: ", err);
            setNftCount(0);
        }
    }

    // Mint NFT
    async function mintNFT() {
        if (!account) return alert("请先连接钱包！");
        if (!mintTo || !/^0x[a-fA-F0-9]{40}$/.test(mintTo)) return alert("请输入有效地址！");

        try {
            const walletClient = createWalletClient({
                chain: sepolia,
                transport: custom(window.ethereum),
            });

            const txHash = await walletClient.writeContract({
                address: CONTRACTS.MyNFT,
                abi: MyNFTABI.abi,
                functionName: "mint",
                args: [mintTo],
                account: account,   // 这里必须传入当前钱包地址
            });

            console.log("交易已发送，hash:", txHash);
            alert("Mint 交易已发送，请等待区块确认");

            // 可选：Mint 完成后刷新 NFT 数量
            await fetchMyNFTs();
        } catch (err) {
            console.error("Mint NFT失败:", err);
            alert("Mint NFT失败，请查看控制台");
        }
    }


    // List NFT
    async function listNFTForSale() {
        if (!account) return alert("请先连接钱包！");

        const { nftAddress, tokenId, price } = listNFT;
        if (!/^0x[a-fA-F0-9]{40}$/.test(nftAddress)) return alert("请输入有效NFT地址！");
        if (!tokenId || isNaN(Number(tokenId))) return alert("请输入有效Token ID！");
        if (!price || isNaN(Number(price)) || Number(price) <= 0) return alert("请输入有效价格！");

        try {
            const walletClient = createWalletClient({
                chain: sepolia,
                transport: custom(window.ethereum),
            });

            const txHash = await walletClient.writeContract({
                address: CONTRACTS.NFTMarket,
                abi: NFTMarketABI.abi,
                functionName: "list",
                args: [nftAddress, tokenId, price],
                account: account,
            });
            console.log("上架交易已发送, hash:", txHash);
            alert("NFT已上架，请等待区块确认");
        } catch (err) {
            console.error("NFT上架失败:", err);
            alert("NFT上架失败，请查看控制台");
        }

    }

    // 购买NFT
    async function buyNFT() {
        if (!account) return alert("请先连接钱包！");

        const { nftAddress, tokenId } = buyNFTInput;
        if (!/^0x[a-fA-F0-9]{40}$/.test(nftAddress)) return alert("请输入有效NFT地址！");
        if (!tokenId || isNaN(Number(tokenId))) return alert("请输入有效Token ID！");

        try {
            const walletClient = createWalletClient({
                chain: sepolia,
                transport: custom(window.ethereum),
            });

            const txHash = await walletClient.writeContract({
                address: CONTRACTS.NFTMarket,
                abi: NFTMarketABI.abi,
                functionName: "buyNFT",
                args: [nftAddress, tokenId],
                account: account,
            });

            console.log("购买交易已发送, hash:", txHash);
            alert("购买NFT交易已发送，请等待区块确认");
        } catch (err) {
            console.error("购买NFT失败:", err);
            alert("购买NFT失败，请查看控制台");
        }
    }

    useEffect(() => {
        if (window.ethereum) {
            window.ethereum.request({ method: "eth_accounts" }).then(async (accounts) => {
                if (accounts.length > 0) {
                    setAccount(accounts[0]);
                }
            });

            window.ethereum.on("accountsChanged", (accounts) => {
                if (accounts.length > 0) {
                    setAccount(accounts[0]);
                } else {
                    setAccount(null);
                    setMyNFTs([]);
                }
            });
        }
    }, []);

    return (
        <div className="app">
            {!account ? (
                <button onClick={connectWallet} className="button">
                    连接钱包
                </button>
            ) : (
                <div>
                    <p>
                        已连接地址: <b>{account}</b>
                    </p>

                    <div className="card">
                        <h2>功能面板</h2>
                        <div className="actions">

                            {/* Mint */}
                            <div className="mint-panel">
                                <input
                                    type="text"
                                    placeholder="输入接收地址"
                                    value={mintTo}
                                    onChange={(e) => setMintTo(e.target.value)}
                                    className="input"
                                />
                                <button className="button" onClick={mintNFT}>
                                    Mint NFT
                                </button>
                            </div>

                            {/* List NFT */}
                            <div className="list-panel">
                                <input
                                    type="text"
                                    placeholder="NFT合约地址"
                                    value={listNFT.nftAddress}
                                    onChange={(e) => setListNFT({ ...listNFT, nftAddress: e.target.value })}
                                    className="input"
                                />
                                <input
                                    type="text"
                                    placeholder="Token ID"
                                    value={listNFT.tokenId}
                                    onChange={(e) => setListNFT({ ...listNFT, tokenId: e.target.value })}
                                    className="input"
                                />
                                <input
                                    type="text"
                                    placeholder="上架价格"
                                    value={listNFT.price}
                                    onChange={(e) => setListNFT({ ...listNFT, price: e.target.value })}
                                    className="input"
                                />
                                <button className="button" onClick={listNFTForSale}>上架NFT</button>
                            </div>

                            {/* Buy NFT */}
                            <div className="buy-panel">
                                <input
                                    type="text"
                                    placeholder="NFT合约地址"
                                    value={buyNFTInput.nftAddress}
                                    onChange={(e) => setBuyNFTInput({ ...buyNFTInput, nftAddress: e.target.value })}
                                    className="input"
                                />
                                <input
                                    type="text"
                                    placeholder="Token ID"
                                    value={buyNFTInput.tokenId}
                                    onChange={(e) => setBuyNFTInput({ ...buyNFTInput, tokenId: e.target.value })}
                                    className="input"
                                />
                                <button className="button" onClick={buyNFT}>购买NFT</button>
                            </div>

                            <button className="disconnect" onClick={() => setAccount(null)}>
                                断开连接
                            </button>
                        </div>
                    </div>

                    <div className="card">
                        <h2>我的NFT</h2>
                        <button className="button" onClick={fetchMyNFTs}>
                            刷新数量
                        </button>
                        <p>你拥有的NFT数量: <b>{nftCount}</b></p>
                    </div>
                </div>
            )}
        </div>
    );
}

export default App;
