// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./IUniswapV2Router01.sol"; //

/**
 * 在 Uniswap V2 中，Router 是交易入口，负责：添加/移除流动性（Liquidity），执行 Swap（代币兑换）与 Pair 合约交互（管理储备、计算价格）
 *
 * 最初的 UniswapV2Router01 仅支持标准 ERC20 代币。但后来很多项目（如 Safemoon、BabyDoge）引入了交易时自动扣手续费的代币（Fee-on-Transfer Token），
 *      这些代币在转账过程中，接收方实际拿到的数量少于发送方发出的数量。这导致 Router01 中的 swap 逻辑无法正确计算输出。
 *
 * 于是 Router02 增加了 SupportingFeeOnTransferTokens 系列函数。
 *
 */

// 在 UniswapV2Router01 的基础上**扩展了对“带手续费转账代币”（Fee-on-Transfer Tokens）**的支持。
/**
 * Router02 的“SupportingFeeOnTransferTokens”系列函数，本质上是对交易时扣手续费的兼容扩展。
 * 它放宽了对 swap 数量一致性的要求，让带手续费代币也能安全参与 AMM 交易，而不会因数额差异失败。
*/
interface IUniswapV2Router02 is IUniswapV2Router01 {
    /**
     * 表示 Router02 继承了 Router01 的所有功能，包括：
     *      - 添加/移除流动性 (addLiquidity, removeLiquidity)
     *      - Swap 相关函数 (swapExactTokensForTokens, swapTokensForExactTokens 等)
     *      - ETH 相关的包装处理（WETH）
     * Router02 在此基础上添加对特殊代币的支持。
     */

    // 移除 token-ETH 交易对中的流动性，并在移除时支持代币扣手续费的逻辑。
    /**
     * 普通版本（在 Router01 中）要求：从 Pair 合约取出的 token 数量 == Router 计算的理论值
     *      但 Fee-on-Transfer 代币会在转账时减少部分数量，因此 Router02 版本不再强制校验接收数量，只要最终接收到的 token 不低于 amountTokenMin 即可。
    */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    // 和上一个函数相同，但额外支持使用 EIP-2612 的 permit 签名授权代替 approve。
    //      即：用户可以用签名直接授权 Router 移除流动性，而不需要提前发起 approve 交易。
    // 省一次交易 gas，用户体验更好（尤其 DApp 场景）
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    // 将一定数量的代币（amountIn）交换为路径末尾的代币。并在过程中支持输入或输出代币带手续费。
    /**
     * 区别于 Router01 的版本：
     *      - 不返回具体的 amounts 数组（因为手续费扣除导致无法精确预测输出）
     *      - 只保证最终收到的数量 ≥ amountOutMin
     *      - 避免因精度偏差触发 require 报错
    */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    // 用一定数量的 ETH（msg.value）兑换路径末尾代币。同样支持带手续费代币。
    /**
     * 流程：
     *      - Router 把 ETH 包装成 WETH；
     *      - 按路径（如 [WETH, TOKEN]）执行兑换；
     *      - 将最终代币转给接收者。
    */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    // 与上一个相反：用带手续费代币换 ETH。
    /**
     * Router 内部：
     *      - 将输入 token 兑换为 WETH；
     *      - 解包 WETH → ETH；
     *      - 转给 to。
     */ 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;





}
