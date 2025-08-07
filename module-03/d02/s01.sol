// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 一个继承自ERC20的token，所有功能都含有了，我们使用的时候直接给出代币基础信息即可
contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("MyToken", "MTK") {
        _mint(msg.sender, initialSupply);
    }
}
// 代币存储银行
/**
    1，owner部署token之后将token给其他一些地址发送一些
    2，其他地址存款之前，需要将token先授权给当前合约这样才可以存入token
**/
contract TokenBank {
    IERC20 public token; // 被存入的 ERC20 代币地址
    mapping(address => uint256) public balances; // 记录每个地址的存入数量

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    /// 存入 TokenBank 的 token
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");

        // 用户需要先调用 token.approve(TokenBank地址, amount)
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "Transfer failed");

        balances[msg.sender] += amount;
    }

    /// 从 TokenBank 取出之前存入的 token
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        bool success = token.transfer(msg.sender, amount);
        require(success, "Transfer failed");
    }

}
