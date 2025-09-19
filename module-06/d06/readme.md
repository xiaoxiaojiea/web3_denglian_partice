
### 基础知识

**Delegate：委托执行**
- 委托给其他合约执行调用


**EOA 是 Externally Owned Account 的缩写，也就是 外部拥有账户**
- EOA账户可以直接理解为是钱包账户，只是一个地址，不像智能合约账户有逻辑代码。
    - 智能合约账户（Contract Account）：部署了代码的地址，无法自己发起交易，只能被调用。
    - 账户抽象（Account Abstraction, AA）：把智能合约的灵活性和 EOA 的控制权结合，让“合约账户”也能像 EOA 一样发起交易。


##### 题目#1 EIP 7702实践：发起打包交易（项目参考 module-05/d01 ）
- 部署自己的 Delegate 合约（Delegate：委托执行，需支持批量执行）到 Sepolia。
- 修改之前的TokenBank 前端页面，让用户能够通过 EOA 账户授权给 Delegate 合约，并在一个交易中完成授权和存款操作。


**题目解析**
- 这个题目跟之前做过的一个很类似，他要掌握两个知识点
    - 委托：委托自己的合约调用请求给第三方合约，让第三方合约替我去执行
    - multicall：合约接受多个调用请求，然后在一个交易中执行
- 这个题目需要写一个 委托合约 来实现 授权+存款，但是我写出来之后发现这个题目有点多余
    - 委托合约将user的代币存款到tokenBank，正常操作如下：
        - user授权 委托合约 可以操作自己的代币
        - 然后user封装multicall去调用 委托合约 ，让他替自己去存款
        - 多余，同样经历了授权+存款
- 所以我作出了修改，不写委托合约，直接在tokenBank中添加了multicall，multicall允许用户的任何调用list，并且打包在一个交易中，真正实现了一次请求多次调用
    - 但是也还有一个问题，授权使用multicall没通过，所以我直接在测试里边授权了，后边可能会修正


**题目解答**
- 项目创建
    - mkdir c01 && cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt
    - wget https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/heads/master.zip -O oz.zip
        - unzip oz.zip -d lib/
        - mv lib/openzeppelin-contracts-master lib/openzeppelin-contracts
        - rm oz.zip
    - 生成 Remappings: forge remappings > remappings.txt

- 编写代码
    - 从 module-05/d01 中将token与tokenbank拷贝过来
    

