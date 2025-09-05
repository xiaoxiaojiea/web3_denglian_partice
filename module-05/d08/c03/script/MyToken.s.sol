// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/MyToken.sol";

contract DeployMyTokenScript is Script {
    function run() external {
        // 开始广播模式，下面的部署交易会在链上实际执行
        vm.startBroadcast();

        // 部署 MyToken 合约
        MyToken myToken = new MyToken("MyToken", "MT");

        vm.stopBroadcast();
    }
}
