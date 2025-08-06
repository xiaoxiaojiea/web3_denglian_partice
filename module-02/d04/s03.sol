// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 被调用合约
contract TargetStatic {
    uint public number = 42;

    function getNumber() public view returns (uint) {
        return number;
    }

    // 这个在 staticcall 中调用会失败
    function tryChange() public {
        number = 100;  
    }
}

// staticcall只能调用pure、view只读函数获取状态，不能修改状态
contract CallerStatic {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    function staticGetNumber() public view returns (uint) {
        bytes memory payload = abi.encodeWithSignature("getNumber()");
        (bool success, bytes memory result) = target.staticcall(payload);
        require(success, "Staticcall failed");
        return abi.decode(result, (uint));
    }

}
