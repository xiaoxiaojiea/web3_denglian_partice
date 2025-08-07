# 登链集训营实战项目全公开（笔记解析）

[项目实战-官网](https://learnblockchain.cn/article/17585)
[项目参考代码](https://github.com/lbc-team/Web3-BootCamp-Practice)
[项目挑战-官网](https://decert.me/)

## 模块一： 区块链基础

#### 实战 1：编码模拟工作量证明（ POW ）过程 与非对称加密应用
- 挑战链接: https://decert.me/quests/45779e03-7905-469e-822e-3ec3746d9ece

- [解题内容](./module-01/d01/)

- ***知识点:***
    - **POW工作量证明原理与实现**：`s01.py`
    - **区块链中签名的含义**：`s02.py`

#### 实战 2： 进阶（可选）：模拟区块链出块过程

- 挑战链接：https://decert.me/quests/ed2d8324-54b0-4b7a-9cee-5e97d3c30030

- [解题内容](./module-01/d02/)

- ***知识点:***
    - **最小区块链的搭建：创世区块，挖矿，上链，验证**：`s01.py`

#### 练习 3： 理解以太坊 GAS 计费规则

- 挑战链接: https://decert.me/quests/d17a9270-99c3-4aeb-8a46-42ecb5e92792

- [解题内容](./module-01/d03/)

- ***知识点:***
    - **Gas的理解与计算**

#### 实战 4：创建和部署第一个智能合约，通过这个挑战熟悉编写、编译、部署合约的全过程，同时掌握Remix 、钱包、区块链浏览器简单使用

- 挑战链接: https://decert.me/quests/61289231665986005978714272641295754558731174328007379661370918963875971676821

- [解题内容](./module-01/d04/)

- ***知识点:***
    - **remix部署一个sepolia测试网智能合约**：`s01.sol`


## 模块二： Solidity语言特性

#### 实战 1：编写Bank，通过实战理解合约账号、并能运用合约接收 ETH，掌握 receive/fallfack函数的使用， payable 使用、及从合约里面转出 ETH，以及映射和数组的使用。

- 挑战链接: https://decert.me/quests/c43324bc-0220-4e81-b533-668fa644c1c3

- [解题内容](./module-02/d01/)

- ***知识点:***
    - **Bank合约编写**
    - **receive/fallfack函数**
    - **payable 使用、及从合约里面转出 ETH**
    - **映射和数组的使用**

#### 实战 2：编写BigBank， 理解并使用合约件的继承、修改器、权限控制以及通过接口作为类型调用其他合约方法。

- 挑战链接: https://decert.me/quests/063c14be-d3e6-41e0-a243-54e35b1dde58

- [解题内容](./module-02/d02/)

- ***知识点:***
    - **接口合约、合约继承、合约重写、合约调用**
    - **函数修饰符public、external、internal、private的作用**
    - **状态可视性修饰符view、pure、payable的作用**
    - **数据位置修饰符memory、storage、calldata的作用**

#### 练习 3： 理解 ABI 编解码规则

- 挑战链接: https://decert.me/quests/10c11aa7-2ccd-4bcc-8ccd-56b51f0c12b8

- [解题内容](./module-02/d03/)

- ***知识点:***
    - **函数选择器、函数签名的ABI编码、solidity中的ABI 编码和解码、call底层调用的payload构建方法**

#### 练习 4：理解 call、delegatecall、staticcall 三种低级函数调用方式

- 挑战链接: https://decert.me/quests/5849ac2d-7a6f-4c94-978c-73c582a575dd

- [解题内容](./module-02/d04/)

- ***知识点:***
    - **call、delegatecall、staticcall的特性与使用**（字少事大）


## 模块三：OpenZepplin 库 Token 及 NFT标准

#### 实战 1：编写一个 ERC20 Token（代币） 合约 ，通过实战进一步熟悉 Solidity 编程，而且可以熟悉 ERC20 Token 合约标准及实现

- 挑战链接: https://decert.me/quests/aa45f136-27a3-4bc9-b4f7-15308e1e0daa

- [解题内容](./module-03/d01/)

- ***知识点:***
    - **本节实战与ERC20之间的关系**
    - **除了原生代币之外的其他币种转账，基本都是对合约内部的balances进行地址的加减而已**
    - **授权余额的mapping组织形式是这样的：代币所有人 => 被批准使用人 => 使用代币数量**


#### 实战 2：实现一个代币银行 TokenBank ，理解合约与合约的交互，理解ERC20 的使用，尤其是 Token 的 transfer， 以及 approve 与 tansferFrom 的组合使用。

- 挑战链接: https://decert.me/quests/eeb9f7d8-6fd0-4c38-b09c-75a29bd53af3

- [解题内容](./module-03/d02/)

- ***知识点:***
    - **官方ERC20的使用**
    - **approve、transferFrom、transfer的含义**






