// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

import {UniswapV2Router02} from "../src/UniswapV2Router02.sol";

contract UniswapV2Router02Script is Script {
    UniswapV2Router02 public uniswapv2router02;

    function setUp() public {}

    function run() public {
        // 设置已经部署的地址
        address uniswapv2factory = 0x538f2323aB718c57920b7cc6B087dbdE1831D398;
        address weth9 = 0x7c83EbA4ff92Ec42239649Cd81d12398bC3fA64D;

        // 读取部署私钥+拿到部署地址
        uint256 deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");  // 环境变量中的私钥
        address deployerAddress = vm.addr(deployerPrivateKey);  // 私钥转为地址
        console.log("Deploying contracts with the account:", deployerAddress);

        // 开始部署（使用这个私钥）
        vm.startBroadcast(deployerPrivateKey);

        // 实例化（需要设置uniswapv2factory, weth9地址）
        uniswapv2router02 = new UniswapV2Router02(uniswapv2factory, weth9);
        console.log("UniswapV2Router02 deployed to: ",address(uniswapv2router02));
        console.log(address(uniswapv2router02));

        // 将部署内容存储下来
        string memory path = "./deployments/UniswapV2Router02.json";
        string memory data = string(
            abi.encodePacked(
                '{"deployerAddress": "',
                vm.toString(address(deployerAddress)),
                '", ',
                '"UniswapV2Router02": "',
                vm.toString(address(uniswapv2router02)),
                '", ',
                '"UniswapV2Factory": "',
                vm.toString(address(uniswapv2factory)),
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
