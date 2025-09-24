// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Interfaces.sol";

/// @title NFT Market V1 (最小、可被代理调用的实现)
contract NFTMarketV1 is IERC20Receiver {
    // Storage layout must be stable across upgrades:
    // 1. listings mapping
    // 2. paymentToken
    // (V2 will append new storage after these)
    struct Listing {
        address seller;
        uint256 price;
        address tokenAddress;
    }

    // NFT 合约地址 => tokenId => Listing
    mapping(address => mapping(uint256 => Listing)) public listings;

    // 接受的支付 ERC20
    IERC20 public paymentToken;

    // Events
    event Listed(address indexed nftAddress, uint256 indexed tokenId, address seller, uint256 price);
    event Bought(address indexed nftAddress, uint256 indexed tokenId, address buyer, uint256 price);
    event Delisted(address indexed nftAddress, uint256 indexed tokenId, address seller);

    // 初始化（替代 constructor）
    function initialize(address _paymentToken) external {
        // 允许只被调用一次 (simple guard)
        require(address(paymentToken) == address(0), "Already initialized");
        require(_paymentToken != address(0), "Invalid token");
        paymentToken = IERC20(_paymentToken);
    }

    // 卖家上架：卖家需先 approve 给本合约或 setApprovalForAll(true)
    function list(address nftAddress, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        require(price > 0, "Price must be > 0");

        // 将 NFT 转入合约托管
        nft.transferFrom(msg.sender, address(this), tokenId);

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            tokenAddress: nftAddress
        });

        emit Listed(nftAddress, tokenId, msg.sender, price);
    }

    // 卖家下架
    function delist(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.price > 0, "Not listed");
        require(item.seller == msg.sender, "Not seller");

        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];
        emit Delisted(nftAddress, tokenId, msg.sender);
    }

    // 买家直接用 ERC20 approve + transferFrom 支付
    function buyNFT(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.price > 0, "Not listed");

        // 转 ERC20 给卖家
        bool ok = paymentToken.transferFrom(msg.sender, item.seller, item.price);
        require(ok, "Payment failed");

        // 转 NFT 给买家
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];
        emit Bought(nftAddress, tokenId, msg.sender, item.price);
    }

    // 回调购买（Token 合约调用）
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override {
        require(msg.sender == address(paymentToken), "Invalid token");

        (address nftAddress, uint256 tokenId) = abi.decode(data, (address, uint256));

        Listing memory item = listings[nftAddress][tokenId];
        require(item.price > 0, "Not listed");
        require(amount >= item.price, "Not enough tokens");

        // 转 NFT 给购买者
        IERC721(nftAddress).transferFrom(address(this), from, tokenId);
        // 转 ERC20 给卖家
        bool ok = IERC20(paymentToken).transfer(item.seller, item.price);
        require(ok, "Transfer to seller failed");

        delete listings[nftAddress][tokenId];
        emit Bought(nftAddress, tokenId, from, item.price);
    }
}
