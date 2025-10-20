// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {AToken} from "../src/AToken.sol";

contract ATokenScript is Script {
    AToken public aToken;

    function setUp() public {}

    function run() public {
        // 读取部署私钥+拿到部署地址
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");  // 环境变量中的私钥
        address deployerAddress = vm.addr(deployerPrivateKey);  // 私钥转为地址
        console.log("Deploying contracts with the account:", deployerAddress);

        // 开始部署（使用这个私钥）
        vm.startBroadcast(deployerPrivateKey);

        // 实例化（需要设置管理员地址）
        aToken = new AToken(deployerAddress);
        console.log("AToken deployed to:", address(aToken));

        // 将部署内容存储下来
        string memory path = "./deployments/AToken.json";
        string memory data = string(
            abi.encodePacked(
                '{"deployerAddress": "',
                vm.toString(address(deployerAddress)),
                '", ',
                '"AToken": "',
                vm.toString(address(aToken)),
                '"}'
            )
        );
        vm.writeJson(data, path);

        // 结束部署
        vm.stopBroadcast();
    }
}
