// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
    MyToken public counter;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        uint256 initialSupply = 600000000000000000000000;
        counter = new MyToken(initialSupply);

        vm.stopBroadcast();
    }
}
