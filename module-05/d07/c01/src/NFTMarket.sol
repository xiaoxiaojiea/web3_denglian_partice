// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NFTMarket {
    IERC20 public paymentToken;  // 市场收款使用的代币
    address public projectSigner;  // 项目方地址，用于给买家签白名单

    // 每个上架的 NFT 会存储
    //      seller：卖家地址
    //      price：标价（ERC20 代币数量）
    struct Listing {
        address seller;
        uint256 price;
    }
    // 映射 listings[nft][tokenId] → 对应的 NFT 出售信息
    mapping(address => mapping(uint256 => Listing)) public listings;

    constructor(address _paymentToken, address _projectSigner) {
        paymentToken = IERC20(_paymentToken);
        projectSigner = _projectSigner;
    }

    // 卖家调用上架
    //      1,把 NFT 转到市场合约里（所以需要事先对合约 approve）。
    //      2,在 listings 里登记价格和卖家。
    function list(address nft, uint256 tokenId, uint256 price) external {
        IERC721(nft).transferFrom(msg.sender, address(this), tokenId);
        listings[nft][tokenId] = Listing(msg.sender, price);
    }

    // 普通购买
    //      1，检查该 NFT 是否已上架。
    //      2，买家支付 paymentToken 给卖家（需要 approve 过市场合约）。
    //      3，市场合约把 NFT 转给买家。
    //      4，删除该 NFT 的出售信息。
    function buy(address nft, uint256 tokenId) public {
        Listing memory item = listings[nft][tokenId];
        require(item.price > 0, "not listed");

        require(paymentToken.transferFrom(msg.sender, item.seller, item.price), "pay fail");
        IERC721(nft).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nft][tokenId];
    }

    // 白名单购买：项目方通过离线签名来控制谁可以买
    // 签名格式（个人签名：eth_sign / personal_sign）： keccak256("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(buyer, nft, tokenId, deadline)))
    function permitBuy(
        address nft,
        uint256 tokenId,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        // 检查时间
        require(block.timestamp <= deadline, "expired");

        // 构造消息：msg.sender（买家地址）+nft（NFT 合约地址）+tokenId（NFT ID）+deadline（有效期）
        bytes32 message = keccak256(abi.encodePacked(msg.sender, nft, tokenId, deadline));
        // 包装成 Ethereum Signed Message（这是 personal_sign / eth_sign 标准格式）
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
        
        // 验证签名人
        address signer = ecrecover(ethHash, v, r, s);
        // 如果恢复出的签名人 == projectSigner（项目方地址），说明签名有效。
        require(signer == projectSigner, "not whitelisted");  

        // 进入普通购买逻辑
        buy(nft, tokenId);
    }
    
}
