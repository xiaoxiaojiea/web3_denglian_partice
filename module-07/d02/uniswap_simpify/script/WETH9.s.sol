// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

import {WETH9} from "../src/WETH9.sol";

contract WETH9Script is Script {
    WETH9 public weth9;

    function setUp() public {}

    function run() public {
        // 读取部署私钥+拿到部署地址
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");  // 环境变量中的私钥
        address deployerAddress = vm.addr(deployerPrivateKey);  // 私钥转为地址
        console2.log("Deploying contracts with the account:", deployerAddress);

        // 开始部署（使用这个私钥）
        vm.startBroadcast(deployerPrivateKey);

        // 实例化
        weth9 = new WETH9();
        console2.log("WETH9 deployed to:");
        console2.log(address(weth9));

        // 将部署内容存储下来
        string memory path = "./deployments/WETH9.json";
        string memory data = string(
            abi.encodePacked(
                '{"deployerAddress": "',
                vm.toString(address(deployerAddress)),
                '", ',
                '"WETH9": "',
                vm.toString(address(weth9)),
                '"}'
            )
        );
        vm.writeJson(data, path);

        // 结束部署
        vm.stopBroadcast();
    }
}
