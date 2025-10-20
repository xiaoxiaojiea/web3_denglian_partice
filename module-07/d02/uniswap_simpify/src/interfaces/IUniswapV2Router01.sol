// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/** Uniswap V2 Router 的标准接口，提供：添加/移除流动性、各种 swap 方式、价格与数量计算工具。
 * 
 * 交换 token A → token B（假设不是 ETH）：
 *      - tokenA.approve(router, amountIn)
 *      - amounts = router.getAmountsOut(amountIn, [tokenA, tokenB])
 *      - minOut = amounts[last] * (1 - slippageTolerance)
 *      - router.swapExactTokensForTokens(amountIn, minOut, [tokenA, tokenB], myAddress, deadline)
 * 
 * 添加流动性（token + ETH）：
 *      - token.approve(router, amountTokenDesired)
 *      - router.addLiquidityETH{value: ethAmount}(token, amountTokenDesired, amountTokenMin, amountETHMin, myAddress, deadline)
 * 
 * 用 permit 移除 LP（省掉 approve）：
 *      - 签名 LP token 的 permit（v,r,s）
 *      - router.removeLiquidityWithPermit(..., v, r, s)
 */

interface IUniswapV2Router01 {
    // 返回工厂合约地址（Uniswap V2 的 UniswapV2Factory），工厂用于创建 Pair（流动性池）。
    function factory() external view returns (address);

    // 返回 Wrapped ETH（WETH）的合约地址。
    function WETH() external view returns (address);

    /** 添加流动性：向 tokenA/tokenB 的交易对中添加流动性，得到 LP 代币（liquidity）。
     * 调用前必须 approve 路由合约把对应的 token 转移权限给路由合约。
     */
    function addLiquidity(
        address tokenA,  // 投入的代币地址
        address tokenB,  // 投入的代币地址
        uint256 amountADesired,  // 希望投入的代币数量（理想值）
        uint256 amountBDesired,  // 希望投入的代币数量（理想值）
        uint256 amountAMin,  // 接受的最小实际投入数量（用于防止前置/滑点）。如果实际投入少于这些值，函数会回退（revert）。
        uint256 amountBMin,  // 接受的最小实际投入数量（用于防止前置/滑点）。如果实际投入少于这些值，函数会回退（revert）。
        address to,  // LP 代币接收地址（通常调用者或指定地址）。
        uint256 deadline  // 时间戳（UNIX），到期后交易不可执行，防止交易长期挂起被前置。
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);  // amountA, amountB：实际添加到池中的数量（可能与 Desired 不同，因为路由会按池中比例调整）。 liquidity：铸造的 LP 代币数量。

    /** 与 addLiquidity 类似，但一侧是 ETH（合约接收 ETH），因此函数带 payable
     * msg.value（发送的 ETH）代表投入的 ETH。
     * amountETHMin：最小可接受的 ETH 数量（滑点保护）。
     * 返回 amountToken, amountETH, liquidity。
     */ 
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )   external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    /** 移除流动性：燃烧（burn）LP 代币，取回池中的两个代币。
     * liquidity：要移除的 LP 代币数量（调用者必须先 approve 路由消耗 LP 代币，或使用 permit）。
    */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,  // amountAMin, amountBMin：滑点保护。
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);  // 返回实际领取的 amountA, amountB。

    /** 一侧为 ETH（路由会把对应的 WETH 兑换/解包为 ETH 并发出）。
     */ 
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    // 允许通过 EIP-2612 风格的 permit（签名授权）来避免提前 approve 的两笔交易（省一笔交易费）。
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    // 允许通过 EIP-2612 风格的 permit（签名授权）来避免提前 approve 的两笔交易（省一笔交易费）。
    function removeLiquidityETHWithPermit(
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
    ) external returns (uint256 amountToken, uint256 amountETH);

    /** Router 最常用的接口，用于不同场景的 token/ETH 兑换 (调用前需 approve 路由合约花费 amountIn)
     */ 
    function swapExactTokensForTokens(
        uint256 amountIn,  // 给定输入数量 amountIn（精确值），换取尽可能多的输出代币
        uint256 amountOutMin,  // 输出至少为 amountOutMin（滑点保护）
        address[] calldata path,  // 交易路径（例如 [tokenA, tokenB, tokenC] 表示 A→B→C 的逐跳兑换），长度至少 2
        address to,  // 接收输出代币的地址
        uint256 deadline
    ) external returns (uint256[] memory amounts);  // 每一跳对应的实际数量数组（amounts[0] = amountIn, amounts[last] = 输出实际数量）。

    /** 
     * 变种 swapTokensForExactTokens(amountOut, amountInMax, path, to, deadline)：目标输出固定，输入最多不超过 amountInMax。适合你需要精确得到某个数量的目标代币。
     */ 
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /** 
     * 变种 swapExactETHForTokens(amountOutMin, path, to, deadline) external payable：用发出的 msg.value ETH 精确兑换代币（payable）。
     */ 
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    /** 
     * 变种 swapETHForExactTokens(amountOut, path, to, deadline) external payable：用 ETH 买固定 amountOut 代币，多余 ETH 会退还。
     */ 
    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    // swapExactTokensForETH(...) / swapTokensForExactETH(...)：与上面对 ETH 的反向对应（输出为 ETH，路由会把 WETH 解包成 ETH 并发送给 to）。
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /**
     * 依据恒定乘积公式（x * y = k），用于计算在给定池内按比例转换 amountA 时应对应的 amountB（不考虑手续费）。
     * pure：仅基于输入计算，不访问链上状态。
     */ 
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    // 给定输入量与储备，计算在考虑交易费（Uniswap V2 默认 0.3%）后的输出量。
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    // 反向，根据期望输出量计算所需输入量。
    // quote,getAmountOut,getAmountIn这些函数在路由内部用于计算逐跳效果，也常被调用者用于预估（例如先计算 getAmountsOut 获取路径上各跳的数量，决定 amountOutMin）。
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    // （多跳）：返回经过 path 各跳后每一步的数量（数组长度 = path.length）。
    //      amounts[0] = amountIn，amounts[i+1] = 根据 amounts[i] 和对应 Pair 的储备计算的输出。
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    // 给定最终输出量反向计算每跳所需输入量数组。
    //      读取链上储备（pair 合约中的 reserve0/reserve1），所以需要 view（不能是 pure）。
    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

}
