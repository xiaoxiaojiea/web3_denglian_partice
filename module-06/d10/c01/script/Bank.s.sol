// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Bank.sol";

contract BankScript is Script {
    function run() external {
        uint256 threshold = 0.001 ether;

        vm.startBroadcast();

        // 部署合约
        Bank bank = new Bank(threshold, msg.sender);

        vm.stopBroadcast();

        console.log("Bank deployed at:", address(bank));
    }

}
