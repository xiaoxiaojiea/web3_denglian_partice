// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {Multicall} from "../src/Multicall.sol";

contract MulticallScript is Script {
    Multicall public multicall;

    function setUp() public {}

    function run() public {
        // 读取部署私钥+拿到部署地址
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");  // 环境变量中的私钥
        address deployerAddress = vm.addr(deployerPrivateKey);  // 私钥转为地址
        console.log("Deploying contracts with the account:", deployerAddress);

        // 开始部署（使用这个私钥）
        vm.startBroadcast(deployerPrivateKey);

        // 实例化
        multicall = new Multicall();
        console.log("Multicall deployed to:", address(multicall));

        // 将部署内容存储下来
        string memory path = "./deployments/Multicall.json";
        string memory data = string(
            abi.encodePacked(
                '{"deployerAddress": "',
                vm.toString(address(deployerAddress)),
                '", ',
                '"Multicall": "',
                vm.toString(address(multicall)),
                '"}'
            )
        );
        vm.writeJson(data, path);

        // 结束部署
        vm.stopBroadcast();
    }
}
