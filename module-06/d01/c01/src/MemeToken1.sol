// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 代币逻辑合约（实现 ERC20 逻辑，但只允许工厂铸造）
contract MemeToken1 is ERC20 {
    address public memeCreator;  // Meme 的创建者地址
    address public factory;  // 工厂合约地址

    uint256 public totalSupply_;  // 总发行量（注意不是 ERC20 的 totalSupply()，而是自己定义的）
    uint256 public perMint;  // 每次铸造的数量
    uint256 public price;  // 每个代币的价格
    uint256 public mintedAmount;  // 已经铸造的数量

    // 现在只是简化版本, 克隆出来的所有 MemeToken，名字都叫 ""，符号是空字符串 ""
    //      因为克隆时constructor没有被执行
    constructor() ERC20("MemeToken1", "MMT") {

    }

    // 类似构造函数（因为最小代理合约 clone 后不会调用 constructor 构造函数，
    //      所以必须自己提供 initialize 来设置状态）
    function initialize(
        string memory _symbol,  // 代币符号
        uint256 _totalSupply,  // 总供应量
        uint256 _perMint,  // 每次铸造的数量
        uint256 _price,  // 每个代币的价格（wei）
        address _creator  // 创建者地址
    ) external {
        // 只能调用一次
        require(memeCreator == address(0), "Already initialized");
        // 设置代币符号、总量、单次 mint 数量、价格、创建者和工厂地址。
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(_perMint > 0, "Per mint must be greater than 0");
        require(_perMint <= _totalSupply, "Per mint must be less than or equal to total supply");
        
        // _setSymbol 这里其实是个占位，真实 OpenZeppelin 的 ERC20 是不能在运行时改 symbol 的，需要自己改源码或用 ERC20Preset
        _setSymbol(_symbol);

        totalSupply_ = _totalSupply;
        perMint = _perMint;
        price = _price;
        memeCreator = _creator;
        factory = msg.sender;  // 设置工厂合约地址为调用初始化函数的地址
        mintedAmount = 0;
    }

    // 设置代币符号
    function _setSymbol(string memory _symbol) internal pure {
        // 由于 ERC20 的 symbol 是不可变的，这里我们使用一个内部函数来设置
        // 在实际部署中，可能需要使用更复杂的方法来处理这个问题
        // 这里简化处理，实际上这个函数在当前 OpenZeppelin 实现中不存在
        // 您可能需要修改 ERC20 合约或使用其他方法来实现这个功能
        _symbol = _symbol;
    }

    // 用户通过代理工厂铸造新的代币
    function mint(address to) external returns (bool) {
        require(msg.sender == factory, "Only factory can mint");  // 使用存储的工厂地址
        require(mintedAmount + perMint <= totalSupply_, "Exceeds total supply");
        
        mintedAmount += perMint;
        _mint(to, perMint);
        return true;
    }
}

