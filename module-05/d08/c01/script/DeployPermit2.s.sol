// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "permit2/Permit2.sol";

contract DeployPermit2Script is Script {
    Permit2 public permit2;

    function run() external {
        vm.startBroadcast();

        // 直接部署官方 Permit2
        permit2 = new Permit2();

        vm.stopBroadcast();
    }
}
