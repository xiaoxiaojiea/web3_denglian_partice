
题目
- 在 Bank 合约基础之上，编写 IBank 接口
- 在 Bank 合约基础之上编写BigBank 合约，使其满足 BigBank 继承自 Bank ， 同时 BigBank 有附加要求：
    - 要求存款金额 >0.001 ether（用modifier权限控制）
    - BigBank 合约支持转移管理员
- 编写一个 Admin 合约， Admin 合约有自己的 Owner ，同时有一个取款函数 adminWithdraw(IBank bank) , adminWithdraw 中会调用 - IBank 接口的 withdraw 方法从而把 bank 合约内的资金转移到 Admin 合约地址。

- BigBank 和 Admin 合约 部署后，把 BigBank 的管理员转移给 Admin 合约地址，模拟几个用户的存款，然后
- Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。

题目分析
- 在bank.sol中将Bank提取出来一个接口IBank，然后Bank实现IBank接口；
- 在BigBank.sol将BigBank继承Bank，然后继承Bank，重写deposit并且添加最小金额限制，然后添加管理员权限转移方法；
- 在admin.sol中，写一个可以调用提取BigBank中withdraw函数的函数，用于把 bank 合约内的资金转移到 Admin 合约地址；

代码执行原理
- 部署BigBank 和 Admin 合约（Bank不用部署，因为他是父类，只提供了一个模板，没有实际使用意义）
- 将BigBank的管理员权限转移给Admin 合约（因为后边BigBank合约的withdraw函数只可以管理员地址调用）
- 普通用户往BigBank中存一些钱
- Admin 合约的Owner地址调用 adminWithdraw(IBank bank) 把 BigBank 的资金转移到 Admin 地址。


函数修饰符public、external、internal、private的作用
- 它们决定了函数能被谁调用（合约外部、合约内部、继承合约）等访问权限
- public：    合约内部可见，   继承合约可见，   合约外部可调用
- external：  合约内部不可见， 继承合约可见，   合约外部可调用
- internal：  合约内部可见，   继承合约可见，   合约外部不可调用
- private：   合约内部可见，   继承合约不可见， 合约外部不可调用


状态可视性修饰符view、pure、payable的作用
- 限制函数行为的修饰符
- view：    只读函数，    函数内不可修改任何状态， 可以读取区块链状态， 常用于查询合约状态
- pure：    纯函数，      函数内不可修改任何状态， 不可读取区块链状态， 常用于数学计算
- payable： 允许接收ETH， 函数内可修改任何状态，   可读取区块链状态，   常用于接收或花费 ETH


数据位置修饰符memory、storage、calldata的作用
- 指定变量存储在哪个位置
- memory：   函数执行期间临时存在， 可读可写， 常用于临时变量、函数中复制数据
- storage：  合约长期状态变量，    可读可写， 常用于合约状态、永久变量
- calldata： 只读、外部调用参数，   只读，    常用于external函数的入参（数组、结构体等）
    - external 函数是供 合约外部调用 的函数，调用方式通常是：用户交易的如钱包调用，其他合约通过 .call() 或接口调用，入参必须从 calldata 中读取
    - 入参自动存储在 calldata 中（只读、不可修改）



