// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

// 支持ERC20Permit离线授权
contract TestToken is ERC20, ERC20Permit {
    constructor() ERC20("TestToken", "TT") ERC20Permit("TestToken") {
        _mint(msg.sender, 1e24); // mint 1 million TT
    }
}
