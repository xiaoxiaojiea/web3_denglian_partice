// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Caller {

    // 允许部署时接收 ETH，不然合约没有eth没法完成后边的转账操作
    constructor() payable {

    }  

    function sendEther(address to, uint256 value) public returns (bool) {
        // 使用 call 发送 ether（call调用的时候本身就可以传递eth）
        (bool success, ) = to.call{value: value}("");
        require(success, "sendEther failed");

        return success;
    }

    receive() external payable {}
}


