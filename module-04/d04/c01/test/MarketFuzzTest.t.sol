// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/MyERC20Token.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarket.sol";

contract NFTMarketFuzzTest is Test {
    // 合约对象
    MyNFT nft;
    NFTMarket market;
    MyToken1 token1;
    MyToken2 token2;
    MyToken3 token3;

    // 用户
    address alice = address(0xA1);
    address bob   = address(0xB1);
    address carol = address(0xC1);
    address dave  = address(0xD1);

    address[] buyers;  // 三个用户的数组

    function setUp() public {
        // 部署 NFT
        nft = new MyNFT("TestNFT", "TNFT");

        // 部署 ERC20
        token1 = new MyToken1();
        token2 = new MyToken2();
        token3 = new MyToken3();

        // 部署市场
        market = new NFTMarket();

        // mint NFT 给 alice
        vm.startPrank(alice);
        for (uint i = 0; i < 5; i++) {
            nft.mint();
        }
        vm.stopPrank();

        // 给各个地址分发 ERC20
        token1.transfer(bob, 10000 ether);
        token1.transfer(carol, 10000 ether);
        token1.transfer(dave, 10000 ether);

        token2.transfer(bob, 10000 ether);
        token2.transfer(carol, 10000 ether);
        token2.transfer(dave, 10000 ether);

        token3.transfer(bob, 10000 ether);
        token3.transfer(carol, 10000 ether);
        token3.transfer(dave, 10000 ether);

        buyers = [bob, carol, dave];
    }

    // 模糊测试：随机价格，随机买家(其实buyers顺序固定,用户并没有做成随机)，不同 ERC20
    function testFuzzRandomListingAndBuying(uint256 randPrice1, uint256 randPrice2, uint256 randPrice3) public {
        vm.assume(randPrice1 > 0 && randPrice1 <= 10000 ether);
        vm.assume(randPrice2 > 0 && randPrice2 <= 10000 ether);
        vm.assume(randPrice3 > 0 && randPrice3 <= 10000 ether);

        address[3] memory tokens;
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);

        // alice 上架三个NFT，每个NFT用不同 ERC20 Token，价格随机
        vm.startPrank(alice);
        for (uint i = 0; i < 3; i++) {
            uint256 price;
            if (i == 0) price = randPrice1;
            if (i == 1) price = randPrice2;
            if (i == 2) price = randPrice3;

            IERC721(nft).approve(address(market), i);
            market.list(address(nft), i, tokens[i], price);

            // 检查事件
            (address seller, address paymentToken, uint256 listingPrice, ) = market.listings(address(nft), i);

            assertEq(seller, alice);
            assertEq(paymentToken, tokens[i]);
            assertEq(listingPrice, price);
        }
        vm.stopPrank();

        // 随机买家购买 NFT
        for (uint i = 0; i < 3; i++) {
            address buyer = buyers[i];  // 购买者
            address tokenAddr = tokens[i];  // token地址
            (, , uint256 price, ) = market.listings(address(nft), i);  // 当前nft价格
            
            vm.startPrank(buyer);
            // buyer approve
            IERC20(tokenAddr).approve(address(market), price);

            market.buyNFT(address(nft), i);

            // 检查 NFT 已经转移给 buyer
            assertEq(nft.ownerOf(i), buyer);

            // 检查 NFTMarket 不持有 ERC20
            uint256 contractBalance = IERC20(tokenAddr).balanceOf(address(market));
            assertEq(contractBalance, 0);
            vm.stopPrank();
        }

    }

}
