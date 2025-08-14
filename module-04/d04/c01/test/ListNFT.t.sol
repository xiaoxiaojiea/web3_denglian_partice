// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/MyERC20Token.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract ListNFTTest is Test {
    // 三个合约对象
    MyToken1 token;
    MyNFT nft;
    NFTMarket market;

    // 两个用户
    address alice = address(0x01);
    address bob = address(0x02);

    function setUp() public {
        // 实例化三个合约对象
        token = new MyToken1();
        nft = new MyNFT("TestNFT", "TNFT");
        market = new NFTMarket();

        // 给 Alice 一些 Token
        token.transfer(alice, 100 ether);
    }

    // 上架成功
    function test_list_success() public {
        // alice mint and 授权给 market
        vm.startPrank(alice);
        nft.mint();
        nft.approve(address(market), 0);

        // 期待后边的交互抛出下边定义的这个emit
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.Listed(alice, address(nft), 0, address(token), 10 ether);  // 这里的ether是个单位而已，不代表ETH

        // 上架交易
        market.list(address(nft), 0, address(token), 10 ether);
        vm.stopPrank();

        // 检查
        (address seller, address paymentToken, uint256 price, ) =
            market.listings(address(nft), 0);
        assertEq(seller, alice);
        assertEq(paymentToken, address(token));
        assertEq(price, 10 ether);
    }

    // 上架失败-非owner
    function test_list_fail_not_owner() public {
        // alice mint 0 号 nft
        vm.startPrank(alice);
        nft.mint();
        vm.stopPrank();

        // bob 上架 0 号 nft
        vm.startPrank(bob);
        vm.expectRevert("Not owner");
        market.list(address(nft), 0, address(token), 1 ether);
        vm.stopPrank();
    }

    // 上架失败-
    function test_list_fail_price_zero() public {
        // alice mint 0 号 nft
        vm.startPrank(alice);
        nft.mint();
        nft.approve(address(market), 0);

        // 上架价格为0
        vm.expectRevert("Price must be > 0");
        market.list(address(nft), 0, address(token), 0);
        vm.stopPrank();
    }

}
