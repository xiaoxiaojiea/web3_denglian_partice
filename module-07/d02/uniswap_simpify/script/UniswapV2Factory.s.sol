// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";

import {UniswapV2Factory} from "../src/UniswapV2Factory.sol";

contract UniswapV2FactoryScript is Script {
    UniswapV2Factory public uniswapv2factory;

    function setUp() public {}

    function run() public {

        // 读取部署私钥+拿到部署地址
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");  // 环境变量中的私钥
        address deployerAddress = vm.addr(deployerPrivateKey);  // 私钥转为地址
        console2.log("Deploying contracts with the account:", deployerAddress);

        // 开始部署（使用这个私钥）
        vm.startBroadcast(deployerPrivateKey);

        // 实例化（需要设置管理员地址）
        uniswapv2factory = new UniswapV2Factory(deployerAddress);
        console2.log("UniswapV2Factory deployed to:");
        console2.log(address(uniswapv2factory));

        // 将部署内容存储下来
        string memory path = "deployed_addresses.json";
        string memory data = string(
            abi.encodePacked(
                '{"deployerAddress": "',
                vm.toString(address(deployerAddress)),
                '", ',
                '"uniswapv2factory": "',
                vm.toString(address(uniswapv2factory)),
                '"}'
            )
        );
        vm.writeJson(data, path);

        // 结束部署
        vm.stopBroadcast();

    }
}
