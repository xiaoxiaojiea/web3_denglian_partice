// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketScript is Script {
    NFTMarket public nftMarket;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address paymentToken = 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318;
        nftMarket = new NFTMarket(paymentToken);

        vm.stopBroadcast();
    }
}
