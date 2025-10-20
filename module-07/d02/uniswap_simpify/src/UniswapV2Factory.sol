// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import "./interfaces/IUniswapV2Factory.sol";  // Uniswap V2 工厂合约的作用：负责部署并管理所有交易对（Pair），记录注册信息，统一收取协议费。
import "./UniswapV2Pair.sol";  // Uniswap V2 交易对 (Pair) 合约 的接口定义，这个接口定义了 流动性操作、交换操作、储备金管理 等核心逻辑。

// Uniswap V2 Factory 工厂合约的核心实现
/**
 * UniswapV2Factory 主要职责如下：
 * 1，管理交易对
 *      - createPair() 创建新 Pair
 *      - getPair[token0][token1] 查询 Pair 地址
 *      - allPairs 记录所有 Pair
 * 2，管理协议费
 *      - feeTo：协议费接收地址
 *      - feeToSetter：有权限修改 feeTo 的管理员
 * 3，地址可预测性
 *      - 使用 CREATE2 部署 Pair，使得 Pair 地址在部署前就能计算。
*/
contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;  // 协议费接收地址
    address public feeToSetter;  // 有权限设置 feeTo 的管理员

    mapping(address => mapping(address => address)) public getPair;  // 保存某两种代币对应的交易对地址
    address[] public allPairs;  // 数组，记录工厂中所有创建过的 Pair 地址

    // 部署时指定初始的 feeToSetter 管理员地址
    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    // 查询所有 Pair 数量（常用于前端分页查询）
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    // 创建交易对 (核心函数)
    /**
     * 1，条件约束；
     * 2，使用CREATE2拿到当前A，B代币的LP Token唯一性地址
     * 3，初始化与保存信息；
    */
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");  // tokenA ≠ tokenB（不能相同代币）

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);  // 自动 排序 token0 < token1（保证唯一性）
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");  // 地址非零
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS"); // 不能重复创建

        // 获取 UniswapV2Pair 的字节码（这段字节码和 CREATE2 一起用来计算 Pair 的确定性地址），并计算哈希值
        bytes memory bytecode = type(UniswapV2Pair).creationCode;  // 返回 Pair 合约部署时的 EVM 字节码
        bytes32 hash = keccak256(abi.encodePacked(bytecode));  // 计算哈希值
        console.log("hash: ");
        console.logBytes32(hash);

        // 使用 CREATE2 部署 Pair（CREATE2 允许合约部署者在合约创建时指定合约地址，这样就可以预先知道新合约的地址。）
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));  // 相同的代币对始终得到相同的 Pair 地址（可预测）
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)  // create2：确定性部署，合约地址可以在链上部署前就计算出来。
        }

        // 初始化 & 保存信息
        IUniswapV2Pair(pair).initialize(token0, token1);  // 调用 pair.initialize(token0, token1) 设置代币对
        getPair[token0][token1] = pair;  // 更新映射 getPair，双向存储
        getPair[token1][token0] = pair;
        allPairs.push(pair);  // 把新 Pair 加入 allPairs

        // 触发 PairCreated 事件
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    // 设置协议费接收人
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");  // 只能由 feeToSetter 调用
        feeTo = _feeTo;  // 修改协议费接收地址
    }

    // 修改管理员
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }

}
