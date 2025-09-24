// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 逻辑合约，存储了一个 owner 和一个 password
//    构造函数：初始化时会把部署者设为 owner，同时设置 password
//    只有在输入正确的 password 时，才允许修改 owner
contract VaultLogic {
    address public owner;
    bytes32 private password;

    constructor(bytes32 _password) public {
        owner = msg.sender;
        password = _password;
    }

    function changeOwner(bytes32 _password, address newOwner) public {
        if (password == _password) {
            owner = newOwner;
        } else {
            revert("password error");
        }
    }
}

contract Vault {
    address public owner; // 金库的拥有者
    VaultLogic logic; // 一个 VaultLogic 合约实例的地址，用来 delegatecall
    mapping(address => uint) deposites; // 记录每个地址存了多少钱
    bool public canWithdraw = false; // 是否开启提现的开关

    // 部署时传入 VaultLogic 的地址，设置金库 owner
    constructor(address _logicAddress) public {
        logic = VaultLogic(_logicAddress);
        owner = msg.sender;
    }

    // 当调用 Vault 中不存在的函数时，会触发 fallback
    fallback() external {
        // 它会把调用的数据 msg.data 转发给 logic 合约，但用 delegatecall 来执行
        //    逻辑在 logic 里，但存储使用 Vault 的存储布局
        //    这意味着 VaultLogic 中的 owner 实际上会映射到 Vault 合约存储中的第一个 slot。
        //    **结果：通过 delegatecall 调用 VaultLogic.changeOwner，可以修改 Vault 合约里的 owner！**
        (bool result, ) = address(logic).delegatecall(msg.data);
        if (result) {
            this;
        }
    }

    // 接受以太币转账。
    receive() external payable {}

    // 用户可以存钱，记到账上余额。
    function deposite() public payable {
        deposites[msg.sender] += msg.value;
    }

    // 解题判断函数
    //    检查金库是否被清空。（明显是 CTF/练习合约里用来判断是否“通关”的标志。）
    function isSolve() external view returns (bool) {
        if (address(this).balance == 0) {
            return true;
        }
    }

    // 开启提现（只有 owner 才能开启提现权限）
    function openWithdraw() external {
        if (owner == msg.sender) {
            canWithdraw = true;
        } else {
            revert("not owner");
        }
    }

    // 提现函数
    //    必须先被 openWithdraw 打开。
    //    存款余额要大于等于 0（这里逻辑上有 bug，应该写 > 0）。
    //    deposites[msg.sender] >= 0 永远为真（因为 uint 永远非负），所以没起到作用
    //    使用 call 没有限制 gas，但容易引发重入攻击（经典的重入风险）。
    function withdraw() public {
        if (canWithdraw && deposites[msg.sender] >= 0) {
            (bool result, ) = msg.sender.call{value: deposites[msg.sender]}("");
            if (result) {
                deposites[msg.sender] = 0;
            }
        }
    }

}
