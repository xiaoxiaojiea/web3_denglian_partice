// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {TestNFT} from "../src/TestNFT.sol";

contract TestNFTScript is Script {
    TestNFT public testNFT;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        testNFT = new TestNFT();

        vm.stopBroadcast();
    }
}
