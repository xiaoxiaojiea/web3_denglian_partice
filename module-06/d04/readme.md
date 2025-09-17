
### 基础知识


##### 题目#1 读取合约私有变量数据

- 使用Viem 利用 getStorageAt 从链上读取 _locks 数组中的所有元素值，并打印出如下内容：
    - locks[0]: user:…… ,startTime:……,amount:……

```Solodity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract esRNT {
    struct LockInfo{
        address user;
        uint64 startTime; 
        uint256 amount;
    }
    LockInfo[] private _locks;

    constructor() { 
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(
                address(uint160(i+1)), 
                uint64(block.timestamp*2-i), 
                1e18*(i+1)
            ));
        }
    }

}
```

解题分析
- _locks 的 LockInfo 结构体：
    - user + startTime 可以打包在一个 slot（32 字节）
    - amount 独占一个 slot（32 字节）
```
struct LockInfo {
    address user;     // 20 bytes
    uint64 startTime; // 8 bytes
    uint256 amount;   // 32 bytes
}
```
- 槽索引计算
    - slot0 = baseSlot + i * 2        → 存储 user + startTime
    - slot1 = slot0 + 1               → 存储 amount
- 解析 user 和 startTime
    - buf0.slice(0, 20)               → 前 20 字节是地址
    - buf0.slice(20, 28)              → 接下来的 8 字节是 startTime
- 解析 amount
    - data1 是 32 字节 hex             → 转 BigInt




环境准备
- 合约创建部署
    - mkdir c01 && cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt

- 项目编写部署
    - src/EsRNT.sol
    - script/EsRNT.s.sol
    - anvil
    - forge script script/EsRNT.s.sol:EsRNTScript --fork-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a

viem脚本环境准备
- 创建 readLocks.mjs 文件写入内容
- 运行：node readLocks.mjs

输入内容如下：

```
jie@jie:~/shj_other_ws/学习记录/web3课程02_登链/module-06/d04$ node readLocks.mjs 
locks.length = 11
locks[0]: user=0x0000000000000000d195c4240000000000000000, startTime=0, amount=1000000000000000000
locks[1]: user=0x0000000000000000d195c4230000000000000000, startTime=0, amount=2000000000000000000
locks[2]: user=0x0000000000000000d195c4220000000000000000, startTime=0, amount=3000000000000000000
locks[3]: user=0x0000000000000000d195c4210000000000000000, startTime=0, amount=4000000000000000000
locks[4]: user=0x0000000000000000d195c4200000000000000000, startTime=0, amount=5000000000000000000
locks[5]: user=0x0000000000000000d195c41f0000000000000000, startTime=0, amount=6000000000000000000
locks[6]: user=0x0000000000000000d195c41e0000000000000000, startTime=0, amount=7000000000000000000
locks[7]: user=0x0000000000000000d195c41d0000000000000000, startTime=0, amount=8000000000000000000
locks[8]: user=0x0000000000000000d195c41c0000000000000000, startTime=0, amount=9000000000000000000
locks[9]: user=0x0000000000000000d195c41b0000000000000000, startTime=0, amount=10000000000000000000
locks[10]: user=0x0000000000000000d195c41a0000000000000000, startTime=0, amount=11000000000000000000
```

