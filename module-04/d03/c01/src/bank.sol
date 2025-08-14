// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract Bank {
    mapping(address => uint) public balances;
    address public owner;

    uint256[3] private top3_amount;
    address[3] private top3_address;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function deposit() public payable {
        balances[msg.sender] += msg.value;

        uint256 idx = 0;
        uint256 min_bal = top3_amount[0];

        // 如果用户已经在 top3 中，直接更新他的金额（如果没有这下边会逻辑是错的，错误原因如下）
        //      假设 Alice 第一次存入 3 ETH → Top3 更新，top3_amount[idx] = 3。
        //      第二次存入 2 ETH → balances[Alice] = 5，应该更新 Top3，但原来的 Top3 里最小余额可能是 0（数组
        //          初始化为 0），此时 min_bal = 0，balances[Alice] > min_bal 成立 → Alice 被替换在 idx=0 的
        //          位置，但是 你可能期望 idx=0 原本就是 Alice。
        for (uint i = 0; i < 3; i++) {
            if (top3_address[i] == msg.sender) {
                top3_amount[i] = balances[msg.sender];
                return;
            }
        }

        // 找到最小金额的位置
        for(uint256 i=1; i<3; i++){
            if(top3_amount[i] < min_bal) {
                idx = i;
                min_bal = top3_amount[i];
            }
        }
        if(balances[msg.sender] > min_bal) {
            top3_amount[idx] = balances[msg.sender];
            top3_address[idx] = msg.sender;
        }
    }

    function withdraw(address user) public onlyOwner {
        uint bal = balances[user];
        require(bal > 0);

        payable(msg.sender).transfer(bal);
        balances[user] = 0;
    }

    function getTop3() public view returns (address[3] memory, uint256[3] memory) {
        return (top3_address, top3_amount);
    }

    receive() external payable {}
    fallback() external payable {}

}

