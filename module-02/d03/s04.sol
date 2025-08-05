// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 辅助合约（需要首先部署）
contract DataStorage {
    string private data;

    function setData(string memory newData) public {
        data = newData;
    }

    function getData() public view returns (string memory) {
        return data;
    }
}

// 主合约
contract DataConsumer {
    address private dataStorageAddress;  // 指向辅助合约的地址

    // 构造函数传入辅助合约的地址（所以要先部署辅助合约）
    constructor(address _dataStorageAddress) {
        dataStorageAddress = _dataStorageAddress;
    }

    // encodeWithSignature + call底层调用：无参函数，解析返回值为字符串
    function getDataByABI() public returns (string memory) {
        // 拿到调用getData()时使用的calldata数据（因为该函数没有入参，所以只用设置函数名字就可以了）
        bytes memory payload = abi.encodeWithSignature("getData()");

        // 用底层调用call调用 getData() 函数（用该函数的地址，然后输入calldata即可）
        (bool success, bytes memory result) = dataStorageAddress.call(payload);
        require(success, "call function failed");  // call需要自行处理返回值

        // 解码返回的 bytes 数据为 string
        return abi.decode(result, (string));
    }

    // encodeWithSignature + call底层调用：有参函数
    function setDataByABI1(string calldata newData) public returns (bool) {
        // 拿到调用setData(string)时使用的calldata数据
        bytes memory payload = abi.encodeWithSignature("setData(string)", newData);
        // 用底层调用call调用 setData(string) 函数（用该函数的地址，然后输入calldata即可）
        (bool success, ) = dataStorageAddress.call(payload);
        return success;
    }

    // 用户外部输入要使用的calldata，然后通过函数选择器构建payload
    function setDataByABI2(string calldata newData) public returns (bool) {
        // 拿到函数选择器
        bytes4 selector = bytes4(keccak256("setData(string)"));
        // 拿到调用setData(string)时使用的calldata数据
        bytes memory payload = abi.encodeWithSelector(selector, newData);
        // 底层调用
        (bool success, ) = dataStorageAddress.call(payload);
        return success;
    }

    // 新的编码函数encodeCall使用方法
    function setDataByABI3(string calldata newData) public returns (bool) {
        // 较新的编码函数（引入于 Solidity 0.8.11），用于对某个函数调用进行 强类型安全的 ABI 编码，推荐用于与合约进行低级调用（如 call）时生成 calldata。
        bytes memory playload = abi.encodeCall(DataStorage.setData, (newData));
        // 相同的底层调用
        (bool success, ) = dataStorageAddress.call(playload);
        return success;
    }

}
