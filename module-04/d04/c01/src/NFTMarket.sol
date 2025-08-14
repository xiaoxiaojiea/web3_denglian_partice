// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarket is Ownable {
    // Listing 表示一个上架的 NFT 信息
    struct Listing {
        address seller;  // 卖家的地址
        address paymentToken;  // 卖家挂出来要接收的ERC20代币
        uint256 price;  // paymentToken代币的标价（单位是 ERC20 代币的最小单位，比如 wei）
        address tokenAddress;  // NFT 合约地址
    }

    // 记录上架的nft信息
    mapping(address => mapping(uint256 => Listing)) public listings; // NFT合约地址 -> 该NFT的ID -> 上架信息

    // 事件定义
    event Listed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, address paymentToken, uint256 price);
    event Delisted(address indexed seller, address indexed nftContract, uint256 indexed tokenId);
    event Bought(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, address priceToken, uint256 price);

    // 构造函数
    constructor() Ownable(msg.sender) {}

    // 卖家上架NFT（需要卖家首先将NFT授权给本合约）
    function list(address nftAddress, uint256 tokenId, address paymentToken, uint256 price) external {
        // nftAddress，tokenId：上架那个nft； paymentToken，price：接受那个token购买

        IERC721 nft = IERC721(nftAddress);  // 该NFT合约
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");  // 保证只有该nft拥有者才可以上架这个nft
        require(price > 0, "Price must be > 0");  // 保证上架价格大于0（这个就是paymentToken数量）

        // 将卖家的该NFT转移到本合约中
        nft.transferFrom(msg.sender, address(this), tokenId);

        // 上架信息记录到变量中
        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            paymentToken: paymentToken,
            price: price,
            tokenAddress: nftAddress
        });

        emit Listed(msg.sender, nftAddress, tokenId, paymentToken, price);
    }

    // 卖家下架NFT
    function delist(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];  // 得到该上架nft的信息
        require(item.price > 0, "Not listed");  // 保证该nft已经上架
        require(item.seller == msg.sender, "Not seller");  // 保证只有该nft的卖家才可以下架

        // 把 NFT 还给卖家
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];  // 删除该上架信息
        emit Delisted(msg.sender, nftAddress, tokenId);
    }

    // 买家通过该市场购买NFT（需要买家首先将Token授权给本合约）
    function buyNFT(address nftAddress, uint256 tokenId) external {
        Listing memory listing = listings[nftAddress][tokenId];  // 得到该上架nft的信息
        require(listing.price > 0, "Not listed");  // 保证该nft已经上架

        // 买家支付 ERC20
        require(!(msg.sender == listing.seller), "cannot buy self");  // 保证该nft已经上架
        require(IERC20(listing.paymentToken).transferFrom(msg.sender, listing.seller, listing.price), "ERC20 transfer failed");

        // 将NFT转移到买家地址
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];  // 删除该上架信息
        emit Bought(msg.sender, nftAddress, tokenId, listing.paymentToken, listing.price);
    }

}
