// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 这个合约实现了一个多签钱包，需要多个持有人（owners）共同确认才能执行交易。核心思想是：提案 → 确认 → 执行 的三步流程。

contract MultiSigWallet {
    // 事件定义
    event Deposit(address indexed sender, uint256 amount);
    event SubmitTransaction(uint256 indexed txId, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txId);
    event RevokeConfirmation(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(uint256 indexed txId);

    // 多签持有人地址列表
    address[] public owners; 
    // 检查地址是否为多签持有人
    mapping(address => bool) public isOwner;
    // 签名门槛（执行交易所需的最小确认数）
    uint256 public threshold;

    // 交易结构（1：普通转账：data 为空，value > 0； 2：合约调用：data 包含函数调用数据）
    struct Transaction {
        address to;  // 交互的目标合约地址
        uint256 value;  // 转账金额（wei）
        bytes data;  // 调用数据（用于合约调用）
        bool executed;  // 是否已执行
    }
    // 交易列表（所有交易提案列表）
    Transaction[] public transactions;

    // 记录每个交易被哪些持有人确认过（记录每个交易的确认状态）
    mapping(uint256 => mapping(address => bool)) public isConfirmed;  // 交易ID => (多签持有人地址 => 是否确认)


    // 修饰符：只有多签持有人可以调用
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    // 修饰符：交易必须存在
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Transaction does not exist");
        _;
    }

    // 修饰符：交易尚未执行
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Transaction already executed");
        _;
    }


    // 构造函数：初始化多签持有人和门槛
    constructor(address[] memory _owners, uint256 _threshold) {
        require(_owners.length > 0, "Owners required");
        require(_threshold > 0 && _threshold <= _owners.length, "Invalid threshold");

        // 设置多签持有人
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner");  // 防止零地址和重复地址
            require(!isOwner[owner], "Duplicate owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        // 设置门槛
        threshold = _threshold;
    }

    // 接收以太币
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 提交交易提案
    function submitTransaction(
        address _to,  // 交互的目标合约地址
        uint256 _value,  // 转账金额（wei）
        bytes memory _data  // 调用数据（用于合约调用）
    ) external onlyOwner returns (uint256) {
        uint256 txId = transactions.length;

        // 添加一个新提案
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit SubmitTransaction(txId, _to, _value, _data);
        
        // 提交者自动确认
        confirmTransaction(txId);
        
        return txId;
    }

    // 确认交易
    function confirmTransaction(uint256 _txId) 
        public 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(!isConfirmed[_txId][msg.sender], "Transaction already confirmed");  // 防止重复确认
        
        isConfirmed[_txId][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txId);

        // 如果达到门槛，自动执行
        if (isTransactionConfirmed(_txId)) {
            executeTransaction(_txId);
        }
    }

    // 撤销确认（允许持有人在交易执行前撤回确认）
    function revokeConfirmation(uint256 _txId) 
        external 
        onlyOwner 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(isConfirmed[_txId][msg.sender], "Transaction not confirmed");
        
        isConfirmed[_txId][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, _txId);
    }

    // 执行交易
    function executeTransaction(uint256 _txId) 
        public 
        txExists(_txId) 
        notExecuted(_txId) 
    {
        require(isTransactionConfirmed(_txId), "Threshold not reached");
        
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        // 使用底层 call 调用执行交易（call{value: X}(data)：最底层的以太坊调用）
        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction execution failed");

        emit ExecuteTransaction(_txId);
    }

    // 检查交易是否达到确认门槛
    function isTransactionConfirmed(uint256 _txId) public view returns (bool) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (isConfirmed[_txId][owners[i]]) {
                count++;
            }
            if (count >= threshold) {
                return true;
            }
        }
        return false;
    }

    // 获取交易确认数量
    function getConfirmationCount(uint256 _txId) public view returns (uint256) {
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (isConfirmed[_txId][owners[i]]) {
                count++;
            }
        }
        return count;
    }

    // 获取所有多签持有人
    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    // 获取交易数量
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    // 获取交易详情
    function getTransaction(uint256 _txId) public view returns (
        address to,
        uint256 value,
        bytes memory data,
        bool executed,
        uint256 confirmationCount
    ) {
        Transaction storage transaction = transactions[_txId];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            getConfirmationCount(_txId)  // 实时计算确认数
        );
    }

}