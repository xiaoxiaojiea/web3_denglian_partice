// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./MemeToken.sol";

// 工厂合约，用最小代理（EIP-1167）方式创建新的 MemeToken 实例，并负责收费和分账。
contract MemeFactory is Ownable {
    using Clones for address;

    address public projectOwner;  // 项目方收手续费的地址
    uint256 public constant PROJECT_FEE_PERCENT = 1;  // 项目方手续费比例（1%）
    address public implementation;  // 基础代币实现的地址
    mapping(address => bool) public deployedTokens;  // 记录哪些代币是通过本工厂部署的

    event MemeDeployed(address indexed tokenAddress, address indexed creator, string symbol, uint256 totalSupply, uint256 perMint, uint256 price);
    event MemeMinted(address indexed tokenAddress, address indexed buyer, uint256 amount, uint256 paid);

    // 构造函数
    constructor(address _projectOwner) Ownable(msg.sender) {
        require(_projectOwner != address(0), "Invalid project owner");

        projectOwner = _projectOwner;  // 项目方地址
        
        // 部署基础代币实现(直接部署一个 MemeToken 作为模板, 保存模板地址)
        implementation = address(new MemeToken());
    }

    // 部署新的 Meme 代币
    function deployInscription(
        string memory name,
        string memory symbol,  // 代币符号
        uint256 totalSupply,  // 总供应量
        uint256 perMint,  // 每次铸造的数量
        uint256 price  // 每个代币的价格（wei）
    ) external returns (address tokenAddr) {  // returns 新部署的代币地址
        require(totalSupply > 0, "Total supply must be greater than 0");
        require(perMint > 0, "Per mint must be greater than 0");
        require(perMint <= totalSupply, "Per mint must be less than or equal to total supply");

        // 使用 Clones 库创建最小代理
        tokenAddr = implementation.clone();
        
        // 调用 initialize 初始化代币参数
        MemeToken(tokenAddr).initialize(name, symbol, totalSupply, perMint, price, msg.sender);
        
        // 记录已部署的代币
        deployedTokens[tokenAddr] = true;
        
        // 触发 MemeDeployed 事件
        emit MemeDeployed(tokenAddr, msg.sender, symbol, totalSupply, perMint, price);
        
        return tokenAddr;
    }

    // 铸造 Meme 代币(任何用户可以调用，用来买 Meme 代币)
    function mintInscription(address tokenAddr) external payable {  // tokenAddr 代币地址
        // 检查是否在工厂部署的
        require(deployedTokens[tokenAddr], "Token not deployed by this factory");
        
        MemeToken token = MemeToken(tokenAddr);
        
        // 检查是否超过总供应量
        require(token.mintedAmount() + token.perMint() <= token.totalSupply_(), "Exceeds total supply");
        
        // 计算需要支付的 ETH - 修改计算方式，与测试保持一致
        uint256 requiredAmount = token.price() * token.perMint() / 1e18;
        require(msg.value >= requiredAmount, "Insufficient payment");
        
        // 计算费用分配
        uint256 projectFee = (requiredAmount * PROJECT_FEE_PERCENT) / 100;  // 1% 给 projectOwner
        uint256 creatorFee = requiredAmount - projectFee;  // 99% 给 memeCreator
        
        // 分配费用
        (bool projectSuccess, ) = payable(projectOwner).call{value: projectFee}("");
        require(projectSuccess, "Project fee transfer failed");
        
        (bool creatorSuccess, ) = payable(token.memeCreator()).call{value: creatorFee}("");
        require(creatorSuccess, "Creator fee transfer failed");
        
        // 铸造代币给用户
        token.mint(msg.sender);
        
        // 退还多余的 ETH
        if (msg.value > requiredAmount) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - requiredAmount}("");
            require(refundSuccess, "Refund failed");
        }
        
        // 触发 MemeMinted 事件
        emit MemeMinted(tokenAddr, msg.sender, token.perMint(), requiredAmount);
    }

    // 允许工厂所有者更新项目方地址
    function updateProjectOwner(address _newProjectOwner) external onlyOwner {
        require(_newProjectOwner != address(0), "Invalid project owner");
        projectOwner = _newProjectOwner;
    }

}
