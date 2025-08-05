// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FunctionSelector {
    uint256 private storedValue;

    function getValue() public view returns (uint) {
        return storedValue;
    }

    function setValue(uint value) public {
        storedValue = value;
    }

    function getFunctionSelector1() public pure returns (bytes4) {
        // getValue函数的签名
        return bytes4(keccak256("getValue()"));
    }

    function getFunctionSelector2() public pure returns (bytes4) {
        // setValue(uint256)函数的签名
        return bytes4(keccak256("setValue(uint256)"));
    }
}
