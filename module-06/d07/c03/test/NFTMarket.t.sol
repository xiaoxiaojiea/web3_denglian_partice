// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/NFTMarketV1.sol";
import "../src/NFTMarketV2.sol";
import "../src/SimpleProxy.sol";
import "../src/MyNFT.sol";
import "../src/MyToken.sol";

contract NFTMarketUpgradeTest is Test {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    MyNFT nft;
    MyToken token;
    NFTMarketV1 v1;
    NFTMarketV2 v2;
    SimpleProxy proxy;

    // 测试账户地址
    address deployer;
    address seller; 
    address buyer;
    
    // 测试私钥（从环境变量或默认账户生成）
    uint256 private deployerPrivateKey;
    uint256 private sellerPrivateKey;
    uint256 private buyerPrivateKey;

    function setUp() public {
        // 使用 Foundry 的默认测试账户私钥
        deployerPrivateKey = vm.envOr("DEPLOYER_PRIVATE_KEY", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        sellerPrivateKey = vm.envOr("SELLER_PRIVATE_KEY", uint256(0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d));
        buyerPrivateKey = vm.envOr("BUYER_PRIVATE_KEY", uint256(0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a));
        
        // 从私钥推导地址
        deployer = vm.addr(deployerPrivateKey);
        seller = vm.addr(sellerPrivateKey);
        buyer = vm.addr(buyerPrivateKey);


        vm.startPrank(deployer);

        // 部署 NFT 和 Token
        nft = new MyNFT("MyNFT", "MNFT");
        nft.mint(seller);  // 给seller发送nft
        token = new MyToken("MyToken", "MTK", 1e24); // 1M tokens

        // 部署 V1 逻辑合约
        v1 = new NFTMarketV1();

        // 部署 Proxy 并初始化 V1
        proxy = new SimpleProxy(address(v1), address(token));

        vm.stopPrank();


        // 给 buyer 转一些 token
        vm.startPrank(deployer);
        token.transfer(buyer, 1e20); // 给seller发送 100 tokens
        vm.stopPrank();
    }

    function testUpgradeKeepsState() public {
        vm.startPrank(seller);  // setUp中给seller发送了nft

        // 卖家 approve proxy
        nft.setApprovalForAll(address(proxy), true);  // nft全部授权给代理

        // V1 上架 NFT
        NFTMarketV1(address(proxy)).list(address(nft), 0, 100);

        // 检查 listing 状态（delegatecall：调用者的 msg.sender 保持不变）
        (address s, uint256 p, address t) = NFTMarketV1(address(proxy))
            .listings(address(nft), 0);
        assertEq(s, seller);
        assertEq(p, 100);
        assertEq(t, address(nft));

        vm.stopPrank();

        // 升级到 V2
        vm.startPrank(deployer);
        v2 = new NFTMarketV2();
        proxy.upgradeTo(address(v2)); // 只升级，不初始化
        vm.stopPrank();

        // 升级后检查 listing 是否保持（delegatecall：调用者的 msg.sender 保持不变）
        (address s2, uint256 p2, address t2) = NFTMarketV2(address(proxy))
            .listings(address(nft), 0);
        assertEq(s2, seller);
        assertEq(p2, 100);
        assertEq(t2, address(nft));
    }


    function testListWithSig() public {
        // 升级到 V2
        vm.startPrank(deployer);
        v2 = new NFTMarketV2();
        proxy.upgradeTo(address(v2));
        vm.stopPrank();

        vm.startPrank(seller);
        // 卖家 approve proxy
        nft.setApprovalForAll(address(proxy), true);  // seller授权全部nft
        vm.stopPrank();

        uint256 tokenId = 0;
        uint256 price = 100;

        // 构造签名：hash = keccak256(abi.encodePacked(market, nftAddress, tokenId, price))
        bytes32 hash = keccak256(
            abi.encodePacked(address(proxy), address(nft), tokenId, price)
        );
        bytes32 ethSignedHash = hash.toEthSignedMessageHash();
        
        // 使用卖家的私钥进行签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPrivateKey, ethSignedHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // 验证签名恢复的地址是否正确
        address recoveredSigner = ECDSA.recover(ethSignedHash, signature);
        assertEq(recoveredSigner, seller, "Recovered signer should match seller");

        // 任何人都可以提交签名
        vm.startPrank(buyer);  // seller签名完的消息可以让别人替他提交交易
        NFTMarketV2(address(proxy)).listWithSig(
            address(nft),
            tokenId,
            price,
            signature
        );
        vm.stopPrank();

        // 检查 listing 是否正确（delegatecall：调用者的 msg.sender 保持不变）
        (address s2, uint256 p2, address t2) = NFTMarketV2(address(proxy))
            .listings(address(nft), tokenId);
        assertEq(s2, seller);
        assertEq(p2, price);
        assertEq(t2, address(nft));

        // 再次使用相同签名应失败，再次提交会报错因为签名已经使用过了
        vm.startPrank(buyer);
        vm.expectRevert();  // 异常抛出没正确捕获到，直接使用通用的即可
        NFTMarketV2(address(proxy)).listWithSig(
            address(nft),
            tokenId,
            price,
            signature
        );
        vm.stopPrank();
    }

}