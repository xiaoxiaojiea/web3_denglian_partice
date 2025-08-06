// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Callee {
    function getData() public pure returns (uint256) {
        return 42;
    }
}

contract Caller {

    function callGetData(address callee) public view returns (uint256 data) {
        // call by staticcall
        bytes memory payload = abi.encodeWithSignature("getData()");
        (bool success, bytes memory result) = callee.staticcall(payload);
        require(success, "staticcall function failed");
        data = abi.decode(result, (uint));

        return data;
    }

}

