import { createPublicClient, http } from "viem";
import { foundry } from "viem/chains";

import { keccak256, pad, toHex } from "viem/utils";  // 工具函数，用于计算存储槽哈希和格式化数据

// 公开客户端：只读操作，不会发交易
const client = createPublicClient({
    chain: foundry,
    transport: http("http://127.0.0.1:8545"),
});

const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3"; // EsRNT 合约部署地址

// _locks 数组在 Solidity 合约里是第一个状态变量，所以它的 存储槽（slot）为 0
const LOCKS_SLOT = 0n;  // 0n 表示 BigInt 类型


async function readLocks() {

    // 1. 读取长度
    //      Solidity 中动态数组的 长度 存储在数组的 slot 位置（这里是 slot 0）
    const lenHex = await client.getStorageAt({  // getStorageAt 返回的是 32 字节十六进制字符串
        address: contractAddress,
        slot: LOCKS_SLOT,
    });
    const len = BigInt(lenHex);  // 用 BigInt 转换为数字
    console.log("locks.length =", len.toString());


    // 2. 基础槽位置 = keccak256(p)
    //      Solidity 规定：动态数组的元素存储在 keccak256(slot) 开始的位置
    //      pad(toHex(LOCKS_SLOT), { size: 32 }) → 将 slot 0 转成 32 字节的 hex
    //      keccak256(...) → 得到数组第一个元素的基础槽地址
    //      BigInt(...) → 转成可用于加减的数字
    const baseSlot = BigInt(
        keccak256(pad(toHex(LOCKS_SLOT), { size: 32 }))
    );


    // 遍历数组读取每个元素
    for (let i = 0n; i < len; i++) {
        // 拿到当卡数据的槽地址
        const slot0 = baseSlot + i * 2n;  // user + startTime 槽地址
        const slot1 = slot0 + 1n;  // amount 槽地址

        // 根据槽地址取出真实数据
        const data0 = await client.getStorageAt({ address: contractAddress, slot: slot0 });
        const data1 = await client.getStorageAt({ address: contractAddress, slot: slot1 });

        // user + startTime共同占用一个槽，所以需要切分
        const buf0 = Buffer.from(data0.slice(2).padStart(64, "0"), "hex");
        const user = "0x" + buf0.slice(0, 20).toString("hex");
        const startTime = BigInt("0x" + buf0.slice(20, 28).toString("hex"));
        // amount独占一个槽
        const amount = BigInt(data1);

        console.log(
            `locks[${i}]: user=${user}, startTime=${startTime}, amount=${amount}`
        );
    }

}

readLocks();
