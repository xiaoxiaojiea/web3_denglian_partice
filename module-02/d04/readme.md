
### 基础内容

**call、delegatecall、staticcall**
- 三种用于与其他合约交互的低级函数调用方式。它们都返回 (bool success, bytes memory data) 类型的返回值，但它们的行为和用途差异很大。
- 场景：钱包A与合约B交互 + 合约B中会调用合约C
- call：当前上下文是：合约 C，使用的是：合约 C 的 storage
    - 通过call()方法调用链：钱包 A → 合约 B → 合约 C
        - B 中的 msg.sender 是 A，C 中的 msg.sender 是 B
        - C 使用 C 自己的 storage
    - 用法：(bool success, bytes memory data) = targetAddress.call(encodedPayload);
    - 特点：
        - 常用于与其他合约交互（可以是动态地址）。
        - 使用的是被调用合约的存储上下文。
        - 能发送 ETH。
        - 可调用目标合约中的任意 public / external 函数。
        - 无类型检查（需要自己构造好函数签名和参数）。
        - 容易出错，不推荐在安全敏感的场景下频繁使用。
- delegatecall：当前上下文是：合约 B，使用的是：合约 B 的 storage；**delegatecall 会保持原始调用者（可以认为delegatecall会把被调用合约的所有内容拷贝到自己合约中）**
    - 通过delegatecall()方法调用链：钱包 A → 合约 B → 合约 C
        - B 中的 msg.sender 是 A，C 中的 msg.sender 是 A
        - C 执行代码，但使用的是 B 的 storage
    - 用法：(bool success, bytes memory data) = targetAddress.delegatecall(encodedPayload);
    - 特点：
        - 常用于代理合约模式（Proxy Pattern）。
        - 执行的是目标地址的代码，但状态变量读写的是当前合约的存储空间。
        - 无法发送 ETH。
        - 合约之间的存储结构必须兼容，否则会破坏状态。
        - 易出安全漏洞（如 delegatecall 到不可控逻辑合约）。
- staticcall：只读调用：不能修改状态，适用于 view/pure 函数调用。
    - 用法：(bool success, bytes memory data) = targetAddress.staticcall(encodedPayload);
    - 特点：
        - 只能调用 view 或 pure 函数。
        - 执行过程中尝试修改状态会被直接回滚。
- **典型用途**
    - 普通合约交互 ⇒ 用 call
    - 代理合约、库合约共享逻辑 ⇒ 用 delegatecall
    - 只读查询函数（如 view/pure） ⇒ 用 staticcall

**代码示例**
- call：见s01.sol
    - call调用目标函数的时候，不会保持原始调用者，并且上下文存储都在被调用合约中
    - 所以CallerCall调用TargetCall设置number的时候，number会被修改到TargetCall合约中；
- deletecall：见s02.sol
    - delegatecall作为调用合约：delegatecall调用目标合约的时候，相当于就是将 被调用合约 所有内容拷贝到 调用合约 中，所以原始调用者不变，上下文内容都在调用合约中
    - **使用 delegatecall 的合约（CallerDelegate）必须 完全复制 被调用合约（TargetDelegate）的存储布局，在顺序、类型、变量名上保持一致。**
        - 如果将CallerDelegate中的 number 与 target 前后顺序交换一个会发现delegateSetNumber会将target修改掉
        - TargetDelegate 合约的存储布局：
            - uint public number;  // slot 0
        - CallerDelegate 合约的存储布局：
            - address public target; // slot 0 ❗️
            - uint public number;    // slot 1 ❗️
- staticcall：见s03.sol
    - staticcall只能调用pure、view只读函数获取状态，不能修改状态




##### 题目1
以下哪个函数调用不会改变调用合约的状态?
- A，call
- B，以上都会改变状态
- C，delegatecall
- D，staticcall

解析：选择D，因为是只读调用（这个题目有误解的可能，他说“不会改变调用合约的状态”，call修改的是被调用合约的状态，调用合约也不会被修改到）

##### 题目2
以下说法正确的是？
- A，call 会在失败时自动回滚事务，而 delegatecall 不会
- B，call 会在被调用合约的存储和上下文中执行其代码
- C，使用 call 发送 Ether 时，gas 默认有限制
- D，delegatecall 会在调用者的上下文中执行被调用合约的代码

解析：选择B，D
- A：call 和 delegatecall 都返回一个 (bool success, bytes memory data)，需要手动判断是否成功
- C：call 没有默认 gas 限制（“transfer/send 有 gas 限制，call 没有限制，默认传递所有 gas”。）

##### 题目3
补充完整 Caller 合约的 callGetData 方法，使用 staticcall 调用 Callee 合约中 getData 函数，并返回值。当调用失败时，抛出“staticcall function failed”异常。

解析：见s04.sol，基础知识往前看

##### 题目4
使用 call 方法来发送 Ether，补充完整 Caller 合约 的 sendEther 方法，用于向指定地址发送 Ether。要求：
- 使用 call 方法发送 Ether
- 如果发送失败，抛出“sendEther failed”异常并回滚交易。
- 如果发送成功，则返回 true

解析：见s05.sol，这个有一些细节需要关注

##### 题目5
call 调用函数, 补充完整 Caller 合约的 callSetValue 方法，用于设置 Callee 合约的 value 值。要求：
- 使用 call 方法调用用 Callee 的 setValue 方法，并附带 1 Ether
- 如果发送失败，抛出“call function failed”异常并回滚交易。
- 如果发送成功，则返回 true

解析：见s06.sol，这个有一些细节需要关注

##### 题目6
使用 delegatecall 调用函数, 补充完整 Caller 合约 的 delegateSetValue 方法，调用 Callee 的 setValue 方法用于设置 value 值。要求：
- 使用 delegatecall
- 如果发送失败，抛出“delegate call failed”异常并回滚交易。

解析：见s07.sol

