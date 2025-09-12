// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// 用于最小代理（Clones）的 ERC20，支持 initialize 设置 name/symbol。
contract MemeToken is ERC20 {
    address public memeCreator;  // Meme 的创建者地址
    address public factory;  // 工厂合约地址

    uint256 public totalSupply_;  // 总发行量（注意不是 ERC20 的 totalSupply()，而是自己定义的）
    uint256 public perMint;  // 每次铸造的数量
    uint256 public price;  // 每个代币的价格
    uint256 public mintedAmount;  // 已经铸造的数量

    // 是否初始化过
    bool private initialized;

    // 额外存储 name 和 symbol（因为 ERC20 的 _name/_symbol 是 immutable）
    string private _customName;
    string private _customSymbol;

    
    constructor() ERC20("", "") {

    }

    // 类似构造函数（因为最小代理合约 clone 后不会调用 constructor 构造函数，
    //      所以必须自己提供 initialize 来设置状态）
    function initialize(
        string memory name_,
        string memory symbol_,  // 代币符号
        uint256 _totalSupply,  // 总供应量
        uint256 _perMint,  // 每次铸造的数量
        uint256 _price,  // 每个代币的价格（wei）
        address _creator  // 创建者地址
    ) external {
        // 只能调用一次
        require(memeCreator == address(0), "Already initialized");
        initialized = true;

        // 设置代币符号、总量、单次 mint 数量、价格、创建者和工厂地址。
        require(_totalSupply > 0, "Total supply must be greater than 0");
        require(_perMint > 0, "Per mint must be greater than 0");
        require(_perMint <= _totalSupply, "Per mint must be less than or equal to total supply");
        
        // set
        _customName = name_;
        _customSymbol = symbol_;

        totalSupply_ = _totalSupply;
        perMint = _perMint;
        price = _price;
        memeCreator = _creator;
        factory = msg.sender;  // 设置工厂合约地址为调用初始化函数的地址
        mintedAmount = 0;
    }

    /// @dev 覆盖 ERC20 的 name() 和 symbol()
    function name() public view override returns (string memory) {
        return _customName;
    }

    function symbol() public view override returns (string memory) {
        return _customSymbol;
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

