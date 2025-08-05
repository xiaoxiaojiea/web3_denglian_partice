// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ABIEncoder {
    function encodeUint(uint256 value) public pure returns (bytes memory) {
        // 单个参数编码
        return abi.encode(value);
    }

    function encodeMultiple(
        uint num,
        string memory text
    ) public pure returns (bytes memory) {
       // 多个参数编码
       return abi.encode(num, text);
    }
}

contract ABIDecoder {
    function decodeUint(bytes memory data) public pure returns (uint) {
        // 单个参数解码
        return abi.decode(data, (uint));
    }

    function decodeMultiple(
        bytes memory data
    ) public pure returns (uint, string memory) {
        // 多个参数解码
        return abi.decode(data, (uint, string));
    }
}