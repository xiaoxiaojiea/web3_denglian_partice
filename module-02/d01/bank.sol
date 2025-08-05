// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

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

