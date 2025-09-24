// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// V2 逻辑合约 - 添加新功能(添加了冻结的功能)，但保持相同的存储布局
contract LogicV2 {
    // 必须保持与 V1 完全相同的存储布局！！！
    
    // 存储槽 0: 由代理合约使用 (implementation, admin)
    
    // 存储槽 1: 与 V1 相同的状态变量
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    string public name;
    string public symbol;
    
    // V2 新增状态变量 - 必须添加到末尾！
    mapping(address => bool) public frozenAccounts;
    uint256 public version = 2;
    
    // 事件
    event Minted(address indexed to, uint256 amount);
    event Transferred(address indexed from, address indexed to, uint256 amount);
    event AccountFrozen(address indexed account);
    event AccountUnfrozen(address indexed account);
    
    // 铸币函数（与 V1 相同）
    function mint(address to, uint256 amount) public {
        require(!frozenAccounts[to], "Account is frozen");
        balances[to] += amount;
        totalSupply += amount;
        emit Minted(to, amount);
    }
    
    // 转账函数（V2 增强版）
    function transfer(address to, uint256 amount) public {
        require(!frozenAccounts[msg.sender], "Your account is frozen");
        require(!frozenAccounts[to], "Recipient account is frozen");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transferred(msg.sender, to, amount);
    }
    
    // V2 新增功能：冻结账户
    function freezeAccount(address account) public {
        frozenAccounts[account] = true;
        emit AccountFrozen(account);
    }
    
    // V2 新增功能：解冻账户
    function unfreezeAccount(address account) public {
        frozenAccounts[account] = false;
        emit AccountUnfrozen(account);
    }
    
    // V2 新增功能：批量转账
    function batchTransfer(address[] memory recipients, uint256[] memory amounts) public {
        require(recipients.length == amounts.length, "Arrays length mismatch");
        require(!frozenAccounts[msg.sender], "Your account is frozen");
        
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        
        require(balances[msg.sender] >= totalAmount, "Insufficient balance");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            require(!frozenAccounts[recipients[i]], "Recipient account is frozen");
            balances[msg.sender] -= amounts[i];
            balances[recipients[i]] += amounts[i];
            emit Transferred(msg.sender, recipients[i], amounts[i]);
        }
    }
    
    // 获取信息（V2 增强版）
    function getInfo() public view returns (string memory, string memory, uint256, uint256) {
        return (name, symbol, totalSupply, version);
    }
    
    // 获取余额（与 V1 相同）
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    // V2 新增：检查账户是否冻结
    function isFrozen(address account) public view returns (bool) {
        return frozenAccounts[account];
    }

}