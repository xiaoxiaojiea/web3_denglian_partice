// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";  // 
// ERC20Permit 是 EIP-2612 的实现，它在标准 ERC20 的基础上增加了 permit 功能
//      用户可以通过 签名 授权 spender（而不是发一笔 approve 交易）。
//      可以用在 Gasless Approve、MetaTx 或 DEX 场景（用户只签名，不需要先花一次 gas 去 approve）。

contract MyToken is ERC20Permit {  // ERC20Permit 本身继承了 ERC20
    // MyToken 继承了 ERC20Permit (EIP-2612)，支持 permit 离线签名授权，允许用户无需提前 approve，直接通过签名 + permit 来完成授权；

    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(msg.sender, initialSupply);
    }
    
}
