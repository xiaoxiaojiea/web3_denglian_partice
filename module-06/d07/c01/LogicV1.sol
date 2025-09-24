// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// V1 逻辑合约 - 只有逻辑，没有状态变量声明
contract LogicV1 {
    // 注意：这里只是定义存储布局，实际存储是在代理合约中
    
    // 存储槽 0: 由代理合约使用 (implementation, admin)
    
    // 存储槽 1: 本合约的状态变量
    uint256 public totalSupply;  // 总供应量
    mapping(address => uint256) public balances;  // 余额
    string public name;  // name
    string public symbol;  // symbol
    
    // 事件
    event Minted(address indexed to, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    
    // 并不使用的构造函数（因为初始化单独给出了一个函数）
    constructor() {

    }

    // 初始化函数（替代构造函数）
    function initialize(string memory _name, string memory _symbol) public {
        name = _name;
        symbol = _symbol;
        totalSupply = 0;
    }
    
    // 铸币函数
    function mint(address to, uint256 amount) public {
        balances[to] += amount;
        totalSupply += amount;
        emit Minted(to, amount);
    }
    
    // 转账函数
    function transfer(address to, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transferred(msg.sender, to, amount);
    }
    
    // 获取信息
    function getInfo() public view returns (string memory, string memory, uint256) {
        return (name, symbol, totalSupply);
    }
    
    // 获取余额
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}