// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IUniswapV2Pair.sol";  // Uniswap V2 交易对 (Pair) 合约 的接口定义，这个接口定义了 流动性操作、交换操作、储备金管理 等核心逻辑。
import "../UniswapV2Pair.sol";
import "./SafeMath.sol";

import {Test, console} from "forge-std/Test.sol";

/** Uniswap V2 的核心数学库: 几乎所有 DEX（包括 PancakeSwap、SushiSwap、TraderJoe）都基于它的逻辑。
 * 主要功能：
 *      - 计算交易对地址（pair 地址）
 *      - 查询储备量（reserves）
 *      - 按比例计算兑换数量（getAmountOut / getAmountIn / quote）
 *      -  支持多跳路径（path）计算（getAmountsOut / getAmountsIn）
 * 
 * Uniswap V2 恒定乘积公式
 *      - x * y = k
 *          - x：池子中 Token A 的储备量
 *          - y：池子中 Token B 的储备量
 *          - k：常数
 *      - 交易时，用户输入 Δx，会得到 Δy，使得：(x + Δx * 0.997) * (y - Δy) = k
 *          - 即有 0.3% 手续费留在池子。
 *      - 这就是所有 getAmountOut / getAmountIn / quote 函数计算的数学基础。
*/
library UniswapV2Library {
    // using SafeMath for uint256;

    // 对两种代币的地址排序（按地址从小到大）。保证任何时候同一对交易对的地址计算结果一致。
    //      因为 Pair 地址是根据 (token0, token1) 生成的，顺序不同会导致不同地址。
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // 计算出 交易对 (Pair) 的合约地址，不需要部署或查询链上。
    //      Uniswap V2 用 CREATE2 创建 pair，因此地址是确定性的，通过计算哈希，可以直接推导出它的地址。
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        /** 计算结果与链上真实 Pair 地址完全一致。
         * hex"ff" 是 CREATE2 的前缀
         * factory 是 UniswapV2Factory 地址
         * keccak256(token0, token1) 唯一标识一对交易对
         * keccak256(bytecode) 是 Pair 合约的初始化代码哈希
        */
        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"ff", factory, keccak256(abi.encodePacked(token0, token1)), keccak256(abi.encodePacked(bytecode))
            )
        );

        // hex"0xd59a4b7a3d30d8afd9bba1a80fac80da0785face48d391ee6bc9535a907f0e0e" // init code hash
        // 直接从 bytes32 类型转换为 address 类型
        pair = address(uint160(uint256(hash)));
    }

    // 查询交易对的 两种代币储备量
    //      若输入为 (USDT, WETH) 返回 reserveA = USDT 储备量, reserveB = WETH 储备量
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();

        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // 根据储备比例，计算 理论兑换比例（不考虑手续费），公式： amountB = amountA * reserveB / reserveA
    //      举例：池子里 100 USDT ↔ 1 ETH，那么 50 USDT ≈ 0.5 ETH
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        // amountB = amountA.mul(reserveB) / reserveA;
        amountB = (amountA * reserveB) / reserveA;
    }

    // 给定输入金额，计算能得到的最大输出金额（包含 0.3% 手续费），公式：
    //      - amountInWithFee = amountIn * 997
    //      - amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee)
    // 手续费为 0.3%，即 997 / 1000。与恒定乘积公式匹配。
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        // 检查输入金额是否大于0
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        // 检查储备金额是否大于0
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        // 计算费用的输入金额 0.997
        // uint256 amountInWithFee = amountIn.mul(997);
        uint256 amountInWithFee = amountIn * 997;
        // 计算分子
        uint256 numerator = amountInWithFee * reserveOut;
        // 计算分母
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        // 计算输出金额
        amountOut = numerator / denominator;
    }

    // 已知想要的输出数量，反推需要投入多少输入代币。
    //      amountIn = ((reserveIn * amountOut * 1000) / (reserveOut - amountOut * 997)) + 1
    //      这个计算是反向求解恒定乘积方程。
    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountIn)
    {
        // 确保输出金额大于0
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        // 确保池子中的资产数量大于0
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        // 计算分子
        uint256 numerator = reserveIn * amountOut * 1000;
        // 计算分母
        uint256 denominator = reserveOut - amountOut * 997;
        // 计算输入金额
        amountIn = (numerator / denominator) + 1;
    }

    // 多跳兑换路径的 正向计算（从输入推导所有中间输出）
    //      - 举例：path = [USDT, WETH, UNI], 则按顺序计算：USDT → WETH → UNI
    //          - 逐步调用 getReserves 与 getAmountOut，得到每一步的输出量, 返回：amounts = [amountIn, out1, out2]
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        // 确保路径长度大于等于2
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        // 创建一个uint256数组，长度为路径长度
        amounts = new uint256[](path.length);
        // 第一个地址为输入金额
        amounts[0] = amountIn;
        // 遍历路径数组
        for (uint256 i; i < path.length - 1; i++) {
            // 获取第i个地址和第i+1个地址的储备量
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1]);
            // 计算第i+1个地址的输出金额
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // 多跳兑换路径的 反向计算（已知想得到的最终输出，反推最少要投入多少）。
    //      - 同理，从路径末尾反向迭代：UNI ← WETH ← USDT, 每一步调用 getReserves + getAmountIn。
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        // 确保路径长度大于等于2
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        // 创建一个uint256数组，长度为路径长度
        amounts = new uint256[](path.length);
        // 把amountOut赋值给数组的最后一个元素
        amounts[amounts.length - 1] = amountOut;
        // 从路径的最后一个元素开始遍历 倒序
        for (uint256 i = path.length - 1; i > 0; i--) {
            // 获取factory，path[i - 1]，path[i]的储备量
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1], // 倒数第二个
                path[i]
            );
            // 输入数额就是下一个的输出数额 由后往前 计算
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

}
