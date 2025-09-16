// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/MyERC20Token.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract BuyNFTTest is Test {
    // 三个合约对象
    MyToken1 token;
    MyNFT nft;
    NFTMarket market;

    // 两个用户
    address alice = address(0xA1);
    address bob = address(0xB2);

    function setUp() public {
        // 实例化三个合约对象
        token = new MyToken1();
        nft = new MyNFT("TestNFT", "TNFT");
        market = new NFTMarket();

        // 资金分配
        token.transfer(alice, 100 ether);
        token.transfer(bob, 100 ether);

        // alice mint NFT
        vm.startPrank(alice);
        nft.mint();
        nft.approve(address(market), 0);  // alice授权给market
        market.list(address(nft), 0, address(token), 10 ether);  // alice上架0号NFT
        vm.stopPrank();
    }

    // 成功购买
    function test_buy_success() public {
        // bob将token授权给market
        vm.startPrank(bob);
        token.approve(address(market), 10 ether);

        // 期望的emit
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.Bought(bob, address(nft), 0);

        // bob购买
        market.buyNFT(address(nft), 0);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), bob);
    }

    // 失败购买-没有上架该nft
    function test_buy_fail_not_listed() public {
        // bob将token授权给market
        vm.startPrank(bob);
        token.approve(address(market), 10 ether);

        // 期望的revert
        vm.expectRevert("Not listed");
        market.buyNFT(address(nft), 999);

        vm.stopPrank();
    }

    // 失败购买-自己买自己
    function test_buy_fail_self_buy() public {
        vm.startPrank(alice);
        token.approve(address(market), 10 ether);

        // 期望报错
        vm.expectRevert("cannot buy self");
        market.buyNFT(address(nft), 0);

        vm.stopPrank();
    }

    // 失败购买-金额不足
    function test_buy_fail_insufficient_allowance() public {
        vm.startPrank(bob);
        token.approve(address(market), 5 ether);

        vm.expectRevert();  // 这里的ERC20 revert有点麻烦,所以就不捕获具体msg了
        market.buyNFT(address(nft), 0);
        vm.stopPrank();
    }

    // 失败购买-NFT已经卖了
    function test_buy_fail_already_sold() public {
        // bob买走
        vm.startPrank(bob);
        token.approve(address(market), 10 ether);
        market.buyNFT(address(nft), 0);

        // 再次购买
        vm.expectRevert("Not listed");
        market.buyNFT(address(nft), 0);
        vm.stopPrank();
    }


}
