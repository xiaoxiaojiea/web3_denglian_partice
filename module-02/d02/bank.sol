// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 接口
interface IBank {
    // external：合约内部不可见，继承合约可见，合约外部可调用
    function deposit() external payable;
    function withdraw(address user) external;
    // view：只读函数，函数内不可修改任何状态， 可以读取区块链状态， 常用于查询合约状态
    // memory：函数执行期间临时存在， 可读可写， 常用于临时变量、函数中复制数据
    function getTop3() external view returns (address[3] memory, uint256[3] memory);
}

// 实例
contract Bank is IBank {  // 实现接口
    mapping(address => uint) public balances;
    address public owner;

    uint256[3] private top3_amount;
    address[3] private top3_address;

    event Deposit(
        address indexed _from,
        uint _value
    );

    event Withdraw(
        address indexed _from,
        uint _value
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function deposit() public virtual override payable {
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
        
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address user) public virtual override onlyOwner {
        uint bal = balances[user];
        require(bal > 0);

        payable(msg.sender).transfer(bal);
        balances[user] = 0;

        emit Withdraw(user, bal);
    }

    function getTop3() public view virtual override returns (address[3] memory, uint256[3] memory) {
        return (top3_address, top3_amount);
    }

    receive() external payable {}
    fallback() external payable {}
}

