// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import "./Interfaces.sol";

/// @title NFT Market V2 - 增加离线签名上架
contract NFTMarketV2 is IERC20Receiver {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // ======= V1 存储布局（完全相同顺序与类型） =======
    struct Listing {
        address seller;
        uint256 price;
        address tokenAddress;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;
    IERC20 public paymentToken;

    event Listed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller,
        uint256 price
    );
    event Bought(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address buyer,
        uint256 price
    );
    event Delisted(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address seller
    );

    // ======= V2 新增存储（必须追加在末尾） =======
    // 标记签名是否已用： signer => tokenId => used
    mapping(address => mapping(uint256 => bool)) public signatureUsed;

    // Initialization (same selector as V1)
    function initialize(address _paymentToken) external {
        require(address(paymentToken) == address(0), "Already initialized");
        require(_paymentToken != address(0), "Invalid token");
        paymentToken = IERC20(_paymentToken);
    }

    // ========== V1 方法（保持行为一致） ==========
    function list(address nftAddress, uint256 tokenId, uint256 price) external {
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner");
        require(price > 0, "Price must be > 0");

        nft.transferFrom(msg.sender, address(this), tokenId);

        listings[nftAddress][tokenId] = Listing({
            seller: msg.sender,
            price: price,
            tokenAddress: nftAddress
        });

        emit Listed(nftAddress, tokenId, msg.sender, price);
    }

    function delist(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.price > 0, "Not listed");
        require(item.seller == msg.sender, "Not seller");

        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];
        emit Delisted(nftAddress, tokenId, msg.sender);
    }

    function buyNFT(address nftAddress, uint256 tokenId) external {
        Listing memory item = listings[nftAddress][tokenId];
        require(item.price > 0, "Not listed");

        bool ok = paymentToken.transferFrom(
            msg.sender,
            item.seller,
            item.price
        );
        require(ok, "Payment failed");

        IERC721(nftAddress).transferFrom(address(this), msg.sender, tokenId);

        delete listings[nftAddress][tokenId];
        emit Bought(nftAddress, tokenId, msg.sender, item.price);
    }

    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external override {
        require(msg.sender == address(paymentToken), "Invalid token");

        (address nftAddress, uint256 tokenId) = abi.decode(
            data,
            (address, uint256)
        );

        Listing memory item = listings[nftAddress][tokenId];
        require(item.price > 0, "Not listed");
        require(amount >= item.price, "Not enough tokens");

        IERC721(nftAddress).transferFrom(address(this), from, tokenId);
        bool ok = IERC20(paymentToken).transfer(item.seller, item.price);
        require(ok, "Transfer to seller failed");

        delete listings[nftAddress][tokenId];
        emit Bought(nftAddress, tokenId, from, item.price);
    }

    // ========== V2 新增：使用离线签名上架 ==========
    /**
     * 客户端准备：
     * 1) 卖家对 Market 合约地址、nftAddress、tokenId、price 做签名：
     *    hash = keccak256(abi.encodePacked(address(this), nftAddress, tokenId, price))
     *    ethSigned = hash.toEthSignedMessageHash()
     *    signature = sign(ethSigned) // 用卖家私钥签名
     * 2) 卖家需先在 NFT 合约上调用 setApprovalForAll(marketAddress, true)
     *
     * 上链调用（任何人都可提交签名，但签名者必须是 token 的 owner）：
     * listWithSig(nftAddress, tokenId, price, signature)
     */
    function listWithSig(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        bytes calldata signature
    ) external {
        require(price > 0, "Price must be > 0");

        bytes32 h = keccak256(
            abi.encodePacked(address(this), nftAddress, tokenId, price)
        );
        bytes32 ethSignedHash = h.toEthSignedMessageHash();
        address signer = ECDSA.recover(ethSignedHash, signature);
        require(signer != address(0), "Invalid signature");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == signer, "Signer not owner");
        require(
            nft.isApprovedForAll(signer, address(this)),
            "Market not approved by owner"
        );
        require(!signatureUsed[signer][tokenId], "Signature already used");

        nft.transferFrom(signer, address(this), tokenId);

        listings[nftAddress][tokenId] = Listing({
            seller: signer,
            price: price,
            tokenAddress: nftAddress
        });
        signatureUsed[signer][tokenId] = true;

        emit Listed(nftAddress, tokenId, signer, price);
    }
    
}