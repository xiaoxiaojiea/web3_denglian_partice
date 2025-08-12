// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Token合约接口
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

// 自定义的 ERC20 接收者接口，用于接收带数据的转账回调
interface IERC20Receiver {
    function tokensReceivedError(address from, uint256 amount, bytes calldata data) external;
    function tokensReceivedSuccess(address from, uint256 amount, bytes calldata data) external;
}

contract NFTMarket is IERC20Receiver, Ownable {
    // Listing 表示一个上架的 NFT 信息
    struct Listing {
        address seller;  // 卖家的地址
        uint256 price;  // 标价（单位是 ERC20 代币的最小单位，比如 wei）
        address tokenAddress;  // NFT 合约地址
    }

    // 记录上架的nft信息
    mapping(address => mapping(uint256 => Listing)) public listings; // NFT合约地址 -> 该NFT的ID -> 上架信息

    // 指定本市场接受的支付代币（一个 ERC20 Token 合约）
    IERC20 public paymentToken;

    // 事件定义
    event Listed(address indexed nftAddress, uint256 indexed tokenId, address seller, uint256 price);
    event Bought(address indexed nftAddress, uint256 indexed tokenId, address buyer, uint256 price);
    event Delisted(address indexed nftAddress, uint256 indexed tokenId, address seller);

    // 构造函数
    constructor(address _paymentToken) Ownable(msg.sender) {
        paymentToken = IERC20(_paymentToken);
    }

    // 卖家上架NFT（需要卖家首先将NFT授权给本合约）
    function list(address nftAddress, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftAddress);  // 该NFT合约
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");  // 保证只有该nft拥有者才可以上架这个nft
        require(price > 0, "Price must be > 0");  // 保证上架价格大于0（这个就是paymentToken数量）

        // 将卖家的该NFT转移到本合约中
        nft.transferFrom(msg.sender, address(this), tokenId);

        // 上架信息记录到变量中
        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            tokenAddress: nftAddress
        });

        emit Listed(nftAddress, tokenId, msg.sender, price);
    }

    // 卖家下架NFT
    function delist(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];  // 得到该上架nft的信息
        require(item.price > 0, "Not listed");  // 保证该nft已经上架
        require(item.seller == msg.sender, "Not seller");  // 保证只有该nft的卖家才可以下架

        // 把 NFT 还给卖家
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];  // 删除该上架信息
        emit Delisted(nftAddress, tokenId, msg.sender);
    }

    // 买家通过该市场购买NFT（需要买家首先将Token授权给本合约）
    function buyNFT(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];  // 得到该上架nft的信息
        require(item.price > 0, "Not listed");  // 保证该nft已经上架

        // 将token转移到卖家地址
        paymentToken.transferFrom(msg.sender, item.seller, item.price);
        // 将NFT转移到买家地址
        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];  // 删除该上架信息
        emit Bought(nftAddress, tokenId, msg.sender, item.price);
    }

    // 回调购买error
    function tokensReceivedError(address from, uint256 amount, bytes calldata data) external override {
        // from：购买nft的人；amount：花费的token数量；data：携带的一些编码后的信息

        // 确保调用该函数的sender是允许使用的token合约地址（因为本nft market只支持这个token作为兑换货币）
        require(msg.sender == address(paymentToken), "Invalid token");  // MyToken调用该函数的时候，sender就是MyToken合约地址

        // 从calldata中解码出传递过来的内容（要购买的nft合约地址，对应的ID）
        (address nftAddress, uint256 tokenId) = abi.decode(data, (address, uint256));

        // 条件判断
        Listing memory item = listings[nftAddress][tokenId];  // 得到该上架nft的信息
        require(item.price > 0, "Not listed");  // 保证该nft已经上架
        require(amount >= item.price, "Not enough tokens");  // 确保转入的token数量足够

        // 将NFT转移到买家地址
        IERC721(nftAddress).transferFrom(address(this), from, tokenId);
        // 将token转移到卖家地址 ****** Error导致的位置 ******
        IERC20(paymentToken).transferFrom(address(this), item.seller, item.price);

        delete listings[nftAddress][tokenId];  // 删除该上架信息
        emit Bought(nftAddress, tokenId, from, item.price);
    }

    function tokensReceivedSuccess(address from, uint256 amount, bytes calldata data) external override {
        // from：购买nft的人；amount：花费的token数量；data：携带的一些编码后的信息

        // 确保调用该函数的sender是允许使用的token合约地址（因为本nft market只支持这个token作为兑换货币）
        require(msg.sender == address(paymentToken), "Invalid token");  // MyToken调用该函数的时候，sender就是MyToken合约地址

        // 从calldata中解码出传递过来的内容（要购买的nft合约地址，对应的ID）
        (address nftAddress, uint256 tokenId) = abi.decode(data, (address, uint256));

        // 条件判断
        Listing memory item = listings[nftAddress][tokenId];  // 得到该上架nft的信息
        require(item.price > 0, "Not listed");  // 保证该nft已经上架
        require(amount >= item.price, "Not enough tokens");  // 确保转入的token数量足够

        // 将NFT转移到买家地址
        IERC721(nftAddress).transferFrom(address(this), from, tokenId);
        // 将token转移到卖家地址
        IERC20(paymentToken).transfer(item.seller, item.price);

        delete listings[nftAddress][tokenId];  // 删除该上架信息
        emit Bought(nftAddress, tokenId, from, item.price);
    }

}
