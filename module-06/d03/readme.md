

### 基础知识

**Solidity 状态变量布局规则**
- 顺序分配 slot：按照声明顺序分配，从 slot 0 开始。
- 动态数据类型（如 string, bytes, mapping）本身不存储数据，而是存储在一个独立位置（通常是 keccak256(slot))；其 槽位中仅保存 “数据位置指针”。
- mapping 类型变量只占一个槽（用于存储 mapping 的哈希基准地址），实际的内容存在 keccak256(key, slot)。
- 值类型（如 address, uint256, bool 等） 占用固定槽位。

**Solidity 状态变量的存储布局**
- 每个状态变量在合约部署后都存放在链上的存储（Storage）中
- 普通变量会依次占用 slot（32 字节一格）
- mapping 和 dynamic array 并不是直接存放数据，而是通过 keccak256(key + slot) 计算位置。

**Yul（内联汇编）的基本操作**
- sload(slot)：从存储读取数据
- sstore(slot, value)：往存储写数据
- caller()：取当前调用者（等价于 msg.sender）
- mstore(pos, val)：往内存写入数据
- 语法基本类似于低级汇编，但嵌套在 Solidity 里面。例如:
```Solodity
assembly {
    let ownerAddr := sload(2)     // 从 slot 2 取 owner
    sstore(2, caller())           // 把 msg.sender 写进 slot 2
}
```


##### 题目#1 使用Solidity内联汇编修改合约Owner地址
- 请填写下方合约中 owner 状态变量的存储插槽位置 slot 值：

```Solodity
contract MyWallet { 
    public string name;                   // slot 0
    private mapping (address => bool) approved; // slot 1
    public address owner;                 // slot 2
}
```
- name 是 string，动态类型 → 占用 slot 0，用于存储字符串数据的引用信息（长度/数据位置）。
- approved 是 mapping(address => bool)，映射类型 → 占用 slot 1，用作 keccak 哈希基准，实际内容存储在 keccak256(key,1) 等位置。
- owner 是 address，值类型 → 直接存储在 slot 2。



##### 题目#2
- 重新修改 MyWallet 合约的 transferOwernship 和 auth 逻辑，使用内联汇编方式来 set和get owner 地址。
- 他题目中的代码在 0.8.20 版本边一不过去，我修改了一下，在 s01-pre.sol 中

题目解析：
- auth 修饰符就是一个权限检查逻辑。
    - 平时我们写 require(msg.sender == owner)，但现在要改成 assembly { ... } 方式，直接从 slot 读 owner。
- constructor 的作用
    - 合约初始化时需要设置 owner = msg.sender。
    - 在汇编里就要用 sstore(2, caller()) 来做
- getter 的生成规则
    - public owner 会自动生成 owner() 的 getter。
    - 但我们删除了 public owner; 变量，就要自己写一个函数，通过 sload 从 slot 2 取出来。
- 修改后的内容见 s01-aft.sol 中

