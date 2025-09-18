// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {TestToken} from "../src/TestToken.sol";

contract TestTokenScript is Script {
    TestToken public testToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        testToken = new TestToken();

        vm.stopBroadcast();
    }
}
