// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 被调用合约
contract TargetCall {
    uint public number;

    function setNumber(uint _num) public {
        number = _num;
    }
}

// call作为调用合约：call调用目标合约的时候，不会保持原始调用者，并且上下文存储都在被调用合约中
contract CallerCall {
    address public target;

    // 设置被调用合约的地址
    constructor(address _target) {
        target = _target;
    }

    // 调用该函数之后，被调用合约中的 number 会被修改，因为上下文存储在被调用合约中
    function callSetNumber(uint _num) public {
        // 生成调用数据
        bytes memory payload = abi.encodeWithSignature("setNumber(uint256)", _num);
        // 使用 call 调用目标合约
        (bool success, ) = target.call(payload);
        require(success, "Call failed");
    }
}
