// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 被调用合约
contract TargetDelegate {
    // 使用 delegatecall 的合约（CallerDelegate）必须 完全复制 被调用合约（TargetDelegate）的存储布局，在顺序、类型、变量名上保持一致。
    uint public number;

    function setNumber(uint _num) public {
        number = _num;
    }
}

// delegatecall作为调用合约：delegatecall调用目标合约的时候，
//      相当于就是将 被调用合约 所有内容拷贝到 调用合约 中，所以原始调用者不变，上下文内容都在调用合约中
contract CallerDelegate {
    // 一定要注意 CallerDelegate 与 TargetDelegate 的边量要对应起来不然会错误，因为他会按照存储空间来寻找边量赋值
    uint public number;

    address public target;

    // 设置被调用合约的地址
    constructor(address _target) {
        target = _target;
    }

    // 调用该函数之后，被调用合约中的 number 不会被修改，调用合约的number会被修改，因为相当于就是将 被调用合约 所有内容拷贝到 调用合约 中
    function delegateSetNumber(uint _num) public {
        bytes memory payload = abi.encodeWithSignature("setNumber(uint256)", _num);
        (bool success, ) = target.delegatecall(payload);
        require(success, "Delegatecall failed");
    }
}
