// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";

// 在 Uniswap V2 中，每个交易对（Pair）本身就是一个 LP 代币（流动性凭证），遵循 ERC20 标准。这个接口就是 LP Token 的接口定义。
/**
 * IUniswapV2ERC20 定义的是 Uniswap V2 LP Token（流动性凭证）的接口，它除了是一个标准的 ERC20 代币，还支持：
 *      - EIP-2612 permit：用户可以通过签名离线授权，别人代为提交交易，无需自己先调用 approve，节省 一次 on-chain 操作和 gas。
 *      - 常见用法：前端 DApp 让用户用钱包签名，然后直接发 permit + swap，实现无感的流动性操作。
*/
interface IUniswapV2ERC20 is IERC20 {  // 接口IUniswapV2ERC20继承自标准IERC20，并扩展了 EIP-2612 的 permit 功能

    // EIP-712 的域分隔符，用于构建签名消息（保证不同合约/链的签名不会互相混淆）
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    // permit 函数对应 签名的消息结构 哈希值（typehash）
    /**
     * 定义了签名的消息结构，在 EIP-2612 里是固定的：
     *      keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    */
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    // 每个地址的签名使用计数器（nonce）（防止签名被重复使用（replay attack））
    function nonces(address owner) external view returns (uint256);

    // 核心函数：基于签名的授权
    /**
     * 允许用户用 离线签名 授权 spender 代替自己花费 LP Token（即无需提前 approve，节省一次交易和 gas）。
     * 参数说明：
     *      - owner：代币持有人
     *      - spender：被授权花费代币的地址
     *      - value：授权额度
     *      - deadline：签名过期时间戳
     *      - v, r, s：签名参数（ECDSA 拆分格式）
     * 调用成功后，相当于执行了 approve(spender, value)
    */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

}
