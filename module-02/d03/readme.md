
### 基础内容


**函数选择器**：是函数签名的前四个字节（bytes4）
- 计算方法：keccak256("functionName(paramTypes)") 的前 4 字节。
- 例子1：function transfer(address recipient, uint256 amount)
    - bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
    - 这个 selector 编码为 4 字节。
- 例子2：function check()
    - bytes4 selector = bytes4(keccak256("check()"));
    - 这个 selector 编码为 4 字节。
- 代码执行：s01.sol 部署后点击 getSelector() 函数即可拿到函数选择器（4字节）
- 例子见：题目3

**函数签名的ABI编码**：函数选择器（函数签名的前四个字节）+ 参数编码规则（ABI 编码）
- 计算函数选择器，然后计算每个参数占用的地址
- 例子：function transfer(address recipient, uint256 amount)
    - bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        - 0xa9059cbb
    - 参数 1：地址: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        - 去掉 0x 后,补齐为 32 字节（64 字符）: 0000000000000000000000005B38Da6a701c568545dCfcB03FcB875f56beddC4
    - 参数 2：uint256: 1000000000000000000
        - 十进制 → 十六进制，补齐为 64 位十六进制：0000000000000000000000000000000000000000000000000de0b6b3a7640000
    - 最终 ABI 编码结果：拼接 selector + 参数
        - 0xa9059cbb0000000000000000000000005b38da6a701c568545dcfcb03fcb875f56beddc40000000000000000000000000000000000000000000000000de0b6b3a7640000
    - 代码执行：s01.sol 部署后点击 encodeTransfer() 函数，然后点击 function_encoded边量 即可拿到结果


**solidity中的ABI 编码和解码**：用于在合约之间或合约与外部应用之间传递参数的关键机制。
- 定义了如何将 Solidity 类型打包为字节数据并传输，以及如何从字节数据解码回 Solidity 类型。
- ABI 编码：
    - abi.encode(...)：编码为完整的动态 ABI 格式（含偏移量），返回 bytes 类型，通常用于外部调用（如 call）或存储。
    - 调用例子：bytes memory data = abi.encode(uint256(123), address(0x123...));
    - 使用例子：用于函数调用编码，自动把 selector 放在开头。
        - bytes4 selector = bytes4(keccak256("transfer(address,uint256)"));
        - bytes memory data = abi.encodeWithSelector(selector, address(0x123), 100);
    - 使用例子：自动生成 selector 并编码，适合动态生成调用数据。
        - abi.encodeWithSignature("transfer(address,uint256)", address(0x123), 100)
- ABI 解码：用于从字节数据中提取变量
    - abi.decode(data, (type1, type2, ...))
    - 调用例子：
        - (bytes memory encoded) = abi.encode(uint(1), address(0x123));
        - (uint a, address b) = abi.decode(encoded, (uint, address));
- 例子见：题目2



##### 题目1
计算以下函数签名的 ABI 编码后的字节大小：function transfer(address recipient, uint256 amount)
- 函数选择器（函数签名的前四个字节）+ 参数编码规则（ABI 编码） = 4 + 32 + 32 = 68

##### 题目2
ABI 编码和解码
- 完善ABIEncoder合约的encodeUint和encodeMultiple函数，使用abi.encode对参数进行编码并返回
- 完善ABIDecoder合约的decodeUint和decodeMultiple函数，使用abi.decode将字节数组解码成对应类型的数据

解：见 s02.sol

解析：部署之后使用编码拿到字节码，然后放到解码里边来解码就可以拿到原始数据了

##### 题目3
函数选择器
- 补充完整getFunctionSelector1函数，返回getValue函数的签名
- 补充完整getFunctionSelector2函数，返回setValue函数的签名

解：见 s03.sol

##### 题目4
encodeWithSignature、encodeWithSelector 和 encodeCall
- 补充完整getDataByABI，对getData函数签名及参数进行编码，调用成功后解码并返回数据
- 补充完整setDataByABI1，使用abi.encodeWithSignature()编码调用setData函数，确保调用能够成功
- 补充完整setDataByABI2，使用abi.encodeWithSelector()编码调用setData函数，确保调用能够成功
- 补充完整setDataByABI3，使用abi.encodeCall()编码调用setData函数，确保调用能够成功

> **这个题目演示了目前的几种合约之间底层调用call的payload构建方法！！！**

解析内容都在代码中了，见 s04.sol
