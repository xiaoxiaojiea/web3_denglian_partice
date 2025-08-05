// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./bank.sol";

contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function adminWithdraw(IBank bank, address user) public onlyOwner {
        bank.withdraw(user);
    }

    receive() external payable {}
    fallback() external payable {}
}
