import express from "express";  // 启动 HTTP 服务器，提供 RESTful API
import db from "./db.js";  // 本地 sqlite 数据库操作（在 db.js 中初始化）
import { createPublicClient, http, type BlockTag } from "viem";  // BlockTag → 类型定义，允许传 "latest", "earliest", 或 bigint 区块号
import { sepolia } from "viem/chains";

// 解析 JSON 请求体
const app = express();
app.use(express.json());

const ERC20_ADDRESS = "0x1a1Dd7994A1bA16BD2a58cd076EbeA69266587D6";

// RC20 的 Transfer 事件 主题哈希值
//      const TRANSFER_TOPIC = ethers.utils.id("Transfer(address,address,uint256)");
const TRANSFER_TOPIC =
    "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";

// 创建一个只读客户端
const client = createPublicClient({
    chain: sepolia,
    transport: http("https://sepolia.infura.io/v3/xxxxxxxxx"),
});

// 索引 Transfer 事件
async function indexTransfers(fromBlock: bigint | BlockTag = 0n, toBlock: bigint | BlockTag = "latest") {

    // 查询日志（事件），过滤条件：
    //      address → 你的 ERC20 合约地址
    //      fromBlock → 起始区块（bigint 类型）
    //      toBlock → 结束区块（可以是 latest）
    //      topics[0] → TRANSFER_TOPIC，即只要 Transfer 事件
    const logs = await client.getLogs({
        address: ERC20_ADDRESS,
        fromBlock,
        toBlock,
        topics: [TRANSFER_TOPIC],
    });
    // 返回的 logs 数组，每个 log 就是一条 Transfer 事件

    // 解析日志并存储数据库
    //      log.topics[1] → Transfer indexed 参数 from
    //      log.topics[2] → Transfer indexed 参数 to
    //      log.data → Transfer indexed 参数 value (uint256)
    for (const log of logs) {
        if (!log.topics[1] || !log.topics[2]) continue;

        // 拿到当前event数据
        const fromAddr = "0x" + log.topics[1].slice(-40);
        const toAddr = "0x" + log.topics[2].slice(-40);
        const amount = BigInt(log.data).toString();

        // 将数据插入 transfers 表
        db.run(
            `
            INSERT OR IGNORE INTO transfers (txHash, fromAddr, toAddr, amount, blockNumber, timestamp)
            VALUES (?, ?, ?, ?, ?, ?)
            `,
            [log.transactionHash, fromAddr, toAddr, amount, Number(log.blockNumber), Date.now()],
            (err) => {
                if (err) console.error(err);
            }
        );
    }

    console.log(`Indexed ${logs.length} transfers`);
}

// REST 接口查询某地址的转账
app.get("/api/transfers/:address", (req, res) => {
    const addr = req.params.address.toLowerCase();
    // 所有 fromAddr 或 toAddr = 该地址的转账记录，按区块号倒序
    //      INSERT OR IGNORE → 避免重复插入相同交易。
    db.all(
        "SELECT * FROM transfers WHERE lower(fromAddr)=? OR lower(toAddr)=? ORDER BY blockNumber DESC",
        [addr, addr],
        (err, rows) => {
            if (err) return res.status(500).json({ error: err.message });
            res.json(rows);
        }
    );
});


// 启动服务 + 首次索引
async function main() {
    await indexTransfers(0n); // 起始区块，用 bigint

    // 可定时增量同步最新区块
    setInterval(async () => {
        const latest = await client.getBlockNumber(); // bigint
        await indexTransfers(latest - 1000n, latest); // 同步最近 1000 个区块
    }, 30_000); // 每 30 秒同步一次

    app.listen(3000, () => {
        console.log("Server running at http://localhost:3000");
    });
}

main();
