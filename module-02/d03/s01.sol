// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AbiEncodeExample {

    bytes public function_encoded;

    function encodeTransfer(address recipient, uint256 amount) public {
        // 函数签名: transfer(address,uint256)
        // 函数选择器是前4字节的 keccak256("transfer(address,uint256)")
        bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));

        // 使用 abi.encodeWithSelector 进行编码
        function_encoded = abi.encodeWithSelector(selector, recipient, amount);
    }

    // 可选函数：返回 selector（0xa9059cbb）
    function getSelector() public pure returns (bytes4) {
        return bytes4(keccak256("transfer(address,uint256)"));
    }
}

