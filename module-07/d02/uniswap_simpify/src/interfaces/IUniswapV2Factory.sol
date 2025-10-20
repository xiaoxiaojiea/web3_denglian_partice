// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Uniswap V2 工厂合约的作用：负责部署并管理所有交易对（Pair），记录注册信息，统一收取协议费。
/**
 * 这个接口定义了 Uniswap V2 工厂的外部交互规范：
 *      - 读功能：查看所有交易对、某个交易对地址、手续费配置。
 *      - 写功能：新增交易对、修改手续费接收人/管理员。
 *      - 事件：记录交易对创建。
 *
 * 在实际使用中：
 *      - Router 会调用 factory.createPair() 来生成新的交易池；
 *      - DApp 前端会用 getPair() 查询某对代币是否已有池子；
 *      - 协议方会设置 feeTo 来收集协议费。
 */
// 接口只包含函数和事件的声明，不实现逻辑
interface IUniswapV2Factory {
    // 当调用 createPair 成功时触发
    /**
     * token0 / token1：交易对的两种代币地址（按地址大小排序，保证唯一性）。
     * pair：新创建的 Pair 合约地址。
     * uint256：当前工厂管理的总 Pair 数量。
     * indexed 修饰符：允许在日志里根据该字段过滤搜索。
     */
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    // （只读函数）返回协议手续费收取的地址，即“手续费的接收人”
    function feeTo() external view returns (address);

    // （只读函数）返回当前可以设置 feeTo地址 的管理员地址
    function feeToSetter() external view returns (address);

    // （只读函数）查询两种代币的交易对地址，如果没有对应的 Pair 会返回零地址
    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    // （只读函数）通过索引访问所有已创建的 Pair 合约地址，相当于 allPairs[index]
    function allPairs(uint256) external view returns (address pair);

    // （只读函数）返回目前已存在的交易对数量
    function allPairsLength() external view returns (uint256);

    // 创建一个新的交易对合约（Pair），并注册到工厂
    /**
     * 会自动排序 token 地址，避免重复
     * 返回新创建的 Pair 合约地址
     * 会触发 PairCreated 事件
     */
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    // 修改手续费接收地址（feeTo）（只能由 feeToSetter返回的地址 调用）
    function setFeeTo(address) external;

    // 修改管理员（feeToSetter）（只能由当前的 feeToSetter 调用）
    function setFeeToSetter(address) external;
}
