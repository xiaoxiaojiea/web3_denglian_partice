// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/MyERC20Token.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract NFTMarketInvariantTest is Test {
    NFTMarket public market;
    MyNFT public nft;

    MyToken1 public token1;
    MyToken2 public token2;
    MyToken3 public token3;

    address alice = address(0xA1);
    address bob   = address(0xB2);
    address carol = address(0xC3);

    function setUp() public {
        // 部署合约
        token1 = new MyToken1();
        token2 = new MyToken2();
        token3 = new MyToken3();

        nft = new MyNFT("MyNFT", "MNFT");
        market = new NFTMarket();

        // mint NFT
        vm.prank(alice); nft.mint();  // tokenId 0
        vm.prank(bob);   nft.mint();  // tokenId 1
        vm.prank(carol); nft.mint();  // tokenId 2

        // 给各个地址分发 ERC20
        token1.transfer(alice, 100 ether);
        token1.transfer(bob, 100 ether);
        token1.transfer(carol, 100 ether);

        token2.transfer(alice, 100 ether);
        token2.transfer(bob, 100 ether);
        token2.transfer(carol, 100 ether);

        token3.transfer(alice, 100 ether);
        token3.transfer(bob, 100 ether);
        token3.transfer(carol, 100 ether);
    }

    function testInvariant_MarketNeverHoldsTokens() public {
        address[3] memory tokens = [address(token1), address(token2), address(token3)];

        // Alice 上架 NFT 0，支付 token1
        vm.startPrank(alice);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, address(token1), 10 ether);
        vm.stopPrank();

        // Bob 上架 NFT 1，支付 token2
        vm.startPrank(bob);
        nft.approve(address(market), 1);
        market.list(address(nft), 1, address(token2), 20 ether);
        vm.stopPrank();

        // Carol 上架 NFT 2，支付 token3
        vm.startPrank(carol);
        nft.approve(address(market), 2);
        market.list(address(nft), 2, address(token3), 30 ether);
        vm.stopPrank();

        // 模拟购买
        vm.startPrank(bob);
        token1.approve(address(market), 10 ether);
        market.buyNFT(address(nft), 0); // Bob 买 Alice 的 NFT
        vm.stopPrank();

        vm.startPrank(alice);
        token2.approve(address(market), 20 ether);
        market.buyNFT(address(nft), 1); // Alice 买 Bob 的 NFT
        vm.stopPrank();

        vm.startPrank(bob);
        token3.approve(address(market), 30 ether);
        market.buyNFT(address(nft), 2); // Bob 买 Carol 的 NFT
        vm.stopPrank();

        // 不可变断言：市场合约中三种 Token 余额均为0
        assertEq(token1.balanceOf(address(market)), 0);
        assertEq(token2.balanceOf(address(market)), 0);
        assertEq(token3.balanceOf(address(market)), 0);
    }

}
