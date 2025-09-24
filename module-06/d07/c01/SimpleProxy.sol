// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// @title 简单透明代理 (EIP-1967)
//      保存状态变量（totalSupply 等），转发调用到逻辑合约。
//      EIP-1967 标准：规定了 implementation 和 admin 的存储槽位置，避免与逻辑合约的状态变量冲突。
contract SimpleProxy {
    // EIP-1967 规范：要求 implementation，admin 地址分别存放在这个槽位里（这样逻辑合约里的 storage slot 0 就不会和代理的实现地址冲突）
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    // 部署代理时：1）设定 管理员 为部署者；2）设置逻辑合约地址；3）构造初始化数据 initData
    constructor(address implementation, string memory name, string memory symbol) {
        _setAdmin(msg.sender);

        // 生成初始化数据并执行
        bytes memory initData = _buildInitData(name, symbol);  // 调用辅助函数
        _setImplementation(implementation);  // 设置实现合约的真实函数：直接使用汇编更新逻辑函数的地址

        // 使用 delegatecall 调用逻辑合约V1的 initialize（注意V2没有initialize函数了）
        if (initData.length > 0) {
            (bool ok, ) = implementation.delegatecall(initData);
            require(ok, "Initialization failed");
        }
    }

    /// @notice 升级逻辑合约（这里没有自动调用新的 initialize，所以如果新逻辑合约有新状态变量，要另外设计 upgradeToAndCall）
    function upgradeTo(address newImplementation) external onlyAdmin {
        // 设置实现合约的真实函数：直接使用汇编更新逻辑函数的地址
        _setImplementation(newImplementation);
    }

    /// @notice 获取当前逻辑合约地址
    function getImplementation() external view returns (address impl) {
        impl = _getImplementation();
    }

    /// @notice 获取代理管理员
    function getAdmin() external view returns (address adm) {
        adm = _getAdmin();
    }

    /// @notice 修改管理员
    function changeAdmin(address newAdmin) external onlyAdmin {
        _setAdmin(newAdmin);
    }

    /// @dev fallback 和 receive 将调用转发给逻辑合约（所有找不到的函数调用（包括转账）都会 转发给逻辑合约）
    fallback() external payable {
        _delegate(_getImplementation());  // 传入逻辑合约地址
    }

    receive() external payable {
        _delegate(_getImplementation());  // 传入逻辑合约地址
    }

    /// =============== 内部函数 ===============

    /// @dev 根据 name 和 symbol 生成初始化数据
    function _buildInitData(string memory name, string memory symbol) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(
            bytes4(keccak256("initialize(string,string)")),
            name,
            symbol
        );
    }

    // delegate 调用，标准的代理转发逻辑（这个代码通用）
    //      1，拷贝调用数据；
    //      2，执行 delegatecall
    //      3，将返回值返回，或 revert
    function _delegate(address implementation) internal {
        // delegatecall 的作用：在 另一个合约的上下文 中执行代码，但读写的 storage、msg.sender、msg.value 全部保留调用者的（也就是代理合约的）。
        // 这样逻辑合约里的函数，其实在修改的是 代理合约的存储槽，用户也永远只跟代理地址交互。

        assembly {
            // 1. 将 calldata（外部传来的函数选择器和参数）复制到内存
            calldatacopy(0, 0, calldatasize())

            // 2. 执行 delegatecall
            let result := delegatecall(
                gas(),              // 把当前所有 gas 给逻辑合约
                implementation,     // 逻辑合约地址
                0,                  // 内存起始位置（我们刚刚复制到 0 开始）
                calldatasize(),     // calldata 的大小
                0,                  // 返回数据写到内存位置 0
                0                   // 先不给返回空间，稍后单独拷贝
            )

            // 3. 把 delegatecall 的返回值拷贝到内存
            returndatacopy(0, 0, returndatasize())

            // 4. 根据结果返回或回退
            switch result
            case 0 {
                // 如果失败，revert，并把逻辑合约的错误信息一起返回
                revert(0, returndatasize())
            }
            default {
                // 如果成功，返回逻辑合约返回的数据
                return(0, returndatasize())
            }
        }
    }

    // 使用汇编读取逻辑合约地址
    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }

    // 设置实现合约的真实函数：直接使用汇编更新逻辑函数的地址
    function _setImplementation(address newImplementation) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    // 使用汇编读取admin地址
    function _getAdmin() internal view returns (address adm) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            adm := sload(slot)
        }
    }

    // 使用汇编设置admin地址
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
