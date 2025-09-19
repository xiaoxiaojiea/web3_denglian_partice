// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBank {
    IERC20 public token; // 被存入的 ERC20 代币地址
    mapping(address => uint256) public balances; // 记录每个地址的存入数量

    struct Call {
        address target;
        bytes callData;
    }

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    // 存入 TokenBank 的 token（用户要先手动 approve，再 deposit）
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");

        // 用户需要先调用 token.approve(TokenBank地址, amount)
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        balances[msg.sender] += amount;
    }

    // 从 TokenBank 取出之前存入的 token
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }


    function multicall(bytes[] calldata data) external {
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, ) = address(this).delegatecall(data[i]);
            require(success, "Multicall execution failed");
        }
    }


}
