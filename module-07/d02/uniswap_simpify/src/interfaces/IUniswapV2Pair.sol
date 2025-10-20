// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IUniswapV2ERC20.sol";  // LP Token 的接口定义

// Uniswap V2 交易对 (Pair) 合约 的接口定义，这个接口定义了 流动性操作、交换操作、储备金管理 等核心逻辑。
//      每一个 Pair = 一个流动性池（LP），管理着两个代币（token0, token1），并且自身发行 ERC20 LP Token（继承自 IUniswapV2ERC20）
//      当用户添加流动性时，合约会给他们铸造 LP Token；当移除流动性时，销毁对应 LP Token 并返还代币。
/**
 * IUniswapV2Pair 就是 Uniswap V2 LP 合约接口，核心要点：
 *      - 继承 ERC20：LP Token 可转账、授权。
 *      - 流动性操作：mint / burn
 *      - 代币交换：swap，基于公式 x * y = k。
 *      - 储备管理：getReserves、sync、skim。
 *      - 预言机支持：价格累计量 price0CumulativeLast / price1CumulativeLast。
 *      - 事件追踪：Mint、Burn、Swap、Sync。
 * 这就是 Uniswap V2 的核心 AMM 池子接口，所有的 Router（路由器）操作最终都会落到 Pair 的这些函数。 
*/

// 储备概念
/**
 * 为什么要区分 “余额” 和 “储备”
 *      - 余额 (balance)：Pair 合约地址真实持有的代币数量（ERC20 的 balanceOf）。
 *      - 储备 (reserve)：Pair 合约自己记录的内部变量，用于定价。
 * 两者可能不一致：
 *      - 交易刚发生，还没调用 sync 更新
 *      - 有人误转代币到 Pair 地址 → 余额增加，但储备没更新。
 * 所以有两个专用函数
 *      - sync()：把储备更新为最新余额。
 *      - skim(to)：把多余的余额转出去（保持储备和余额一致）。
 * 储备 (reserves) = 池子里两种代币的账面库存，决定了 AMM 的定价和 k 值，是 Uniswap V2 交易逻辑的核心。
*/
interface IUniswapV2Pair is IUniswapV2ERC20 {  // Pair 本身继承了 IUniswapV2ERC20，所以 它也是一个 ERC20（LP Token）
    
    // 当用户添加流动性时触发：amount0/amount1：实际注入池子的代币数量。
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    // 当用户移除流动性时触发，to：代币接收者。
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    // 当发生交换时触发。amountXIn：输入代币数量；amountXOut：输出代币数量；to：接收输出代币的地址。
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    // 当池子内储备更新时触发。reserve0/reserve1：最新储备。
    event Sync(uint112 reserve0, uint112 reserve1);

    // 最小流动性数量（一般是 1000 单位），会永久锁定在池子里，避免除零错误和攻击。
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    // 创建该 Pair 的工厂合约地址。
    function factory() external view returns (address);

    // 该池子管理的两种代币地址（按地址大小排序）。
    function token0() external view returns (address);
    function token1() external view returns (address);

    // 返回当前池子里两种代币的储备量，以及最后一次更新的时间戳。储备值是 AMM 定价公式 x * y = k 的关键参数。
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    // 用于 TWAP（时间加权平均价格） 预言机的累积价格数据。
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);

    // 上一次 reserve0 * reserve1 的结果（k 值），用于计算协议费（fee）。
    function kLast() external view returns (uint256);


    // 添加流动性
    /**
     * 用户先把 token0、token1 转到 Pair，再调用 mint，合约会：
     *      - 计算新增的流动性额度（liquidity）。
     *      - 铸造 LP Token 给 to。
    */
    function mint(address to) external returns (uint256 liquidity);

    // 移除流动性
    /**
     * 用户把 LP Token 发送回 Pair，并调用 burn，合约会：
     *      - 销毁对应数量的 LP Token。
     *      - 按比例返还 token0、token1 给 to。
    */
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    // 进行代币交换
    /**
     * - amount0Out/amount1Out：用户想要拿走的代币数量。
     * - to：代币接收者。
     * - data：额外参数，如果非空会触发 闪电贷 (flash swap)。
    */
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    // 将池子里 多余的代币（非储备部分）转给 to。（避免有人错误转账代币到 Pair 地址）
    function skim(address to) external;

    // 强制更新储备（reserve0/1），与合约实际余额同步。（用于处理异常情况）
    function sync() external;

    // Pair 的构造过程被拆分
    /**
     * 工厂合约 createPair 会部署 Pair 后，调用 initialize 传入两个代币地址。
     *      避免 Pair 构造函数参数过多，降低 gas
     * 只有工厂能调用一次，之后不能修改
     * 
    */
    function initialize(address, address) external;

}
