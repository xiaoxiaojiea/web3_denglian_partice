// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";
import "../src/TokenBank.sol";

contract DeployTokenBankScript is Script {
    function run() external {
        // 启动广播模式，下面的操作会实际在链上发交易
        vm.startBroadcast();

        // 部署 TokenBank，需要传入 ERC20 代币地址
        // 这里假设你已经在 Anvil 上部署了测试 ERC20 token
        address testTokenAddress = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512; // 替换成实际 token 地址
        TokenBank tokenBank = new TokenBank(testTokenAddress);

        vm.stopBroadcast();
    }
}
