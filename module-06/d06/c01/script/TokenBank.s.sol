// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenBank} from "../src/TokenBank.sol";

contract TokenBankScript is Script {
    TokenBank public tokenBank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        address tokenAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
        tokenBank = new TokenBank(tokenAddress);

        vm.stopBroadcast();
    }
}
