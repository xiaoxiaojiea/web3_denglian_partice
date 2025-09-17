// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {EsRNT} from "../src/EsRNT.sol";

contract EsRNTScript is Script {
    EsRNT public esRNT;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        esRNT = new EsRNT();

        vm.stopBroadcast();
    }
}
