// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
    MyToken public myToken;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        string memory name = "MyNFTToken";
        string memory symbol = "MNT";
        uint256 initialSupply = 6000000000000000000000000;  // 6000000
        myToken = new MyToken(name, symbol, initialSupply);

        vm.stopBroadcast();
    }
}
