// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MyWallet { 
    string public name;                       // slot 0
    mapping (address => bool) private approved; // slot 1
    // address public owner;                  // slot 2 (状态变量（address public owner;）真的会在 slot 里占据存储空间。) 

    // 常量 OWNER_SLOT 表示solt 2（不会真的「定义」某个插槽，而只是告诉你「我打算用 slot 2 来存 数据）
    uint256 private constant OWNER_SLOT = 2;

    modifier auth {
        address currentOwner;

        assembly {
            currentOwner := sload(OWNER_SLOT)
        }

        require(msg.sender == currentOwner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;

        // 将msg.sender存放在slot 2位置；（caller()：取当前调用者（等价于 msg.sender））
        assembly {
            sstore(OWNER_SLOT, caller())
        }
    } 

    function transferOwnership(address _addr) external auth {
        require(_addr != address(0), "New owner is the zero address");

        address currentOwner;
        assembly {
            currentOwner := sload(OWNER_SLOT)
        }
        require(currentOwner != _addr, "New owner is the same as the old owner");

        // 修改sender
        assembly {
            sstore(OWNER_SLOT, _addr)
        }
    }

    // getter for owner (手动写 getter)
    function owner() public view returns (address o) {
        // 使用底层操作取slot 2的数据（也就是我们一开始存储的sender）
        assembly {
            o := sload(OWNER_SLOT)
        }
    }
}
