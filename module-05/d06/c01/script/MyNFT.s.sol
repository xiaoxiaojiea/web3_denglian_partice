// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyNFT} from "../src/MyNFT.sol";

contract MyNFTScript is Script {
    MyNFT public myNFT;

    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        string memory tokenName = "MyNFTToken2";
        string memory tokenSymbol = "MNT2";
        myNFT = new MyNFT(tokenName, tokenSymbol);

        vm.stopBroadcast();
    }
}
