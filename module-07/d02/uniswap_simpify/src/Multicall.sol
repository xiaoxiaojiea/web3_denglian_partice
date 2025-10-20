// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// https://cn.etherscan.com/address/0x5e227ad1969ea493b43f840cff78d08a6fc17796#code

/** Multicall 合约（多调用聚合器），它的功能是在一次交易中批量执行多个合约函数调用，并一次性返回所有结果。这个版本是最基础的 Multicall 实现，非常经典、简单、也是很多 DeFi 项目中常用的基础工具。
 * 比如：
 *      - 你想同时读取多个智能合约的状态；
 *      - 或一次性调用多个合约函数；
 *      - 而不是发起多笔交易。
 * 
 * 这在 DeFi 中常见，比如：
 *      - 一次性读取多个代币余额；
 *      - 获取多个交易池的价格；
 *      - 组合多个合约查询。
*/

contract Multicall {
    // 定义一个结构体 Call，代表一次单独的调用：
    struct Call {
        address target;  // 要调用的目标合约地址；
        bytes callData;  // 调用的数据，即目标函数的 ABI 编码（abi.encodeWithSelector 或 abi.encodeWithSignature 生成）。
    }

    /** 接收一组调用请求，按顺序依次执行，返回：1）当前区块号；2）每次调用的返回数据（按顺序存入数组）。
     * 比如：
            const calls = [
            {
                target: tokenA.address,
                callData: tokenA.interface.encodeFunctionData("balanceOf", [user]),
            },
            {
                target: tokenB.address,
                callData: tokenB.interface.encodeFunctionData("balanceOf", [user]),
            },
            ];
    */
    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = block.number;  // 记录当前区块号，确保所有调用都在同一块执行（数据同步）。

        returnData = new bytes[](calls.length);  // 创建一个动态数组，存储每次调用返回的结果。
        for (uint256 i = 0; i < calls.length; i++) {
            // 底层调用方式（低级调用），用于向任意地址发送任意函数数据
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success);  // 如果任意一次调用失败，则整个交易回滚。
            returnData[i] = ret;
        }
    }
    // Helper functions

    // 返回任意地址的 ETH 余额（单位 wei）
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    // 返回指定区块号的哈希（Solidity 原生函数 blockhash() 只能返回 最近 256 个区块的哈希。）
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    // 返回上一个区块的哈希。
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(block.number - 1);
    }

    // 当前区块的时间戳（以秒为单位）。（可用于价格预言机、验证延迟、时间锁合约等。）
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    // 可用于链上伪随机源（尽管不安全用于高价值 randomness）。
    // 以太坊合并后（The Merge）EVM 引入 block.prevrandao 字段。之前是 block.difficulty，现在表示随机值（Beacon chain RANDAO 输出）。
    function getCurrentBlockPrevrandao() public view returns (uint256 prevrandao) {
        prevrandao = block.prevrandao;
    }

    // 返回当前区块的 gas 上限。
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    // 返回当前区块的出块者（验证者）地址。
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }
}
