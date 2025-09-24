// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title 简单透明代理 (EIP-1967)
contract SimpleProxy {
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    event Upgraded(address indexed implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    constructor(address implementation, string memory name, string memory symbol) {
        _setAdmin(msg.sender);
        _setImplementation(implementation);

        // 调用 V1 的 initialize(string,string)
        bytes memory initData = abi.encodeWithSelector(
            bytes4(keccak256("initialize(string,string)")),
            name,
            symbol
        );

        (bool ok, ) = implementation.delegatecall(initData);
        require(ok, "Initialization failed");
    }

    function upgradeTo(address newImplementation) external onlyAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes calldata data) external onlyAdmin {
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

    fallback() external payable {
        require(msg.sender != _getAdmin(), "Admin cannot call fallback");
        _delegate(_getImplementation());
    }

    receive() external payable {
        require(msg.sender != _getAdmin(), "Admin cannot call receive");
        _delegate(_getImplementation());
    }

    // ---------------- internal ----------------
    function _delegate(address implementation) internal {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { impl := sload(slot) }
    }

    function _setImplementation(address newImplementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly { sstore(slot, newImplementation) }
    }

    function _getAdmin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly { adm := sload(slot) }
    }

    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly { sstore(slot, newAdmin) }
    }

    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "Not admin");
        _;
    }
}
