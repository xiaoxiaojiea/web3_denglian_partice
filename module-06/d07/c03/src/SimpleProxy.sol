// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract SimpleProxy {
    bytes32 private constant IMPLEMENTATION_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    // 部署：设置 admin、implementation，并可调用初始化函数 initialize(address)
    constructor(address implementation, address paymentToken) {
        _setAdmin(msg.sender);
        _setImplementation(implementation);

        // 调用逻辑合约的 initialize(address)
        bytes memory initData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(address)")),
            paymentToken
        );

        if (initData.length > 0) {
            (bool ok, ) = implementation.delegatecall(initData);
            require(ok, "Initialization failed");
        }
    }

    // 升级实现合约（admin）
    function upgradeTo(address newImplementation) external onlyAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    // 升级并调用（admin）
    function upgradeToAndCall(
        address newImplementation,
        bytes calldata data
    ) external onlyAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
        if (data.length > 0) {
            (bool ok, ) = newImplementation.delegatecall(data);
            require(ok, "upgradeToAndCall failed");
        }
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        address prev = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(prev, newAdmin);
    }

    // fallback/receive: 转发给 implementation，但禁止 admin 通过 fallback 调用逻辑
    fallback() external payable {
        require(msg.sender != _getAdmin(), "Admin cannot call fallback");
        _delegate(_getImplementation());
    }

    receive() external payable {
        require(msg.sender != _getAdmin(), "Admin cannot call receive");
        _delegate(_getImplementation());
    }

    // ============== internal proxy logic ==============
    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            // delegatecall：调用者的 msg.sender 保持不变
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    function _setImplementation(address newImplementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function _getAdmin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Not admin");
        _;
    }
}
