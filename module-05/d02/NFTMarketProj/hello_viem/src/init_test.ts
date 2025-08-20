import { createPublicClient, http, getContract } from "viem";
import { foundry } from "viem/chains";

// ABI-JSON
import NFTMarket_JSON from "./abis/NFTMarket.json" with { type: "json" };
// ABI
const NFTMarket_ABI = NFTMarket_JSON.abi;
// contract
const NFTMarket_ADDRESS = "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e";

const client = createPublicClient({
  chain: foundry,
  transport: http("http://127.0.0.1:8545"), // 连接本地Anvil或Hardhat
});

const contract = getContract({
  address: NFTMarket_ADDRESS,
  abi: NFTMarket_ABI,
  client,
});

async function main() {
  console.log("📡 Start listening NFTMarket events...\n");

  // 监听 Listed 事件
  client.watchContractEvent({
    address: NFTMarket_ADDRESS,
    abi: NFTMarket_ABI,
    eventName: "Listed",
    onLogs: (logs) => {
      logs.forEach((log) => {
        console.log(
          `🟢 Listed: NFT ${log.args.tokenId} from ${log.args.seller} at price ${log.args.price} (contract ${log.args.nftAddress})`
        );
      });
    },
  });

  // 监听 Delisted 事件
  client.watchContractEvent({
    address: NFTMarket_ADDRESS,
    abi: NFTMarket_ABI,
    eventName: "Delisted",
    onLogs: (logs) => {
      logs.forEach((log) => {
        console.log(
          `⚪️ Delisted: NFT ${log.args.tokenId} by ${log.args.seller} (contract ${log.args.nftAddress})`
        );
      });
    },
  });

  // 监听 Bought 事件
  client.watchContractEvent({
    address: NFTMarket_ADDRESS,
    abi: NFTMarket_ABI,
    eventName: "Bought",
    onLogs: (logs) => {
      logs.forEach((log) => {
        console.log(
          `🛒 Bought: NFT ${log.args.tokenId} from ${log.args.nftAddress}, buyer ${log.args.buyer}, price ${log.args.price}`
        );
      });
    },
  });
}

main().catch((err) => console.error(err));
