// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 定义了3个ERC20代币

contract MyToken1 is ERC20, Ownable {

    constructor() 
        ERC20("MyToken1", "MT1") 
        Ownable(msg.sender) {

        _mint(msg.sender, 600000000000000000000000);  // 600000
    }
    
}

contract MyToken2 is ERC20, Ownable {

    constructor() 
        ERC20("MyToken2", "MT2") 
        Ownable(msg.sender) {

        _mint(msg.sender, 600000000000000000000000);  // 6000
    }
    
}

contract MyToken3 is ERC20, Ownable {

    constructor() 
        ERC20("MyToken3", "MT3") 
        Ownable(msg.sender) {

        _mint(msg.sender, 600000000000000000000000);  // 6000
    }
    
}
