// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./bank.sol";


contract BigBank is Bank {

    modifier minimumDeposit() {
        require(msg.value > 0.001 ether, "Deposit must be > 0.001 ETH");
        _;
    }

    // 重写 deposit，添加金额限制
    function deposit() public payable override minimumDeposit {
        super.deposit();
    }

    // 转移管理员权限
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        owner = newOwner;
    }

}
