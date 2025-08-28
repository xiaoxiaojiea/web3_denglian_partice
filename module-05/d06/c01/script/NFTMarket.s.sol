// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketScript is Script {
    NFTMarket public nftMarket;

    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        address paymentToken = address(0x48aB4cdd2bE0F059efE71c410F08216D3b656892);
        nftMarket = new NFTMarket(paymentToken);

        vm.stopBroadcast();
    }
}
