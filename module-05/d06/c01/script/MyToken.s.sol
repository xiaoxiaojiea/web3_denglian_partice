// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenScript is Script {
    MyToken public myToken;

    function setUp() public {}
    
    function run() public {
        vm.startBroadcast();

        string memory tokenName = "MyToken2";
        string memory tokenSymbol = "MT2";
        uint256 initialSupply = 6000000000000000000000000;  // 6，000，000 个
        myToken = new MyToken(tokenName, tokenSymbol, initialSupply);

        vm.stopBroadcast();
    }
}
