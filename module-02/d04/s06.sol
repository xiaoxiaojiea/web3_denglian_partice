// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Callee {
    uint256 value;

    function getValue() public view returns (uint256) {
        return value;
    }

    function setValue(uint256 value_) public payable {
        require(msg.value > 0);
        value = value_;
    }
}

contract Caller {
    // 允许部署时接收 ETH，不然合约没有eth没法完成后边的转账操作
    constructor() payable {

    }  

    function callSetValue(address callee, uint256 value) public returns (bool) {
        // 生成调用数据
        bytes memory payload = abi.encodeWithSignature("setValue(uint256)", value);
        // 使用 call 调用目标合约
        (bool success, ) = callee.call{value: 1 ether}(payload);
        require(success, "call function failed");

        return success;
    }
}


