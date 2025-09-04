# 登链集训营实战项目全公开（笔记解析）

[项目实战-官网](https://learnblockchain.cn/article/17585)
[项目参考代码](https://github.com/lbc-team/Web3-BootCamp-Practice)
[项目挑战-官网](https://decert.me/)

## 重要案例
- [解题内容](./module-important/)

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

#### 实战 3：编写直接 ERC721 NFT 合约 ，通过实战进一步熟悉 Solidity 编程，而且可以熟悉 ER721 Token 合约标准及实现，以及掌握去中心化存储（如 IPFS）的使用。

- 挑战链接: https://decert.me/quests/852f5836-a03d-4483-a7e0-b0f6f8bda01c

- [解题内容](./module-03/d03/)

- ***知识点:***
    - **NFT基础知识**
    - **NFT与普通coin的不同点**
    - **NFT合约实现的大致模板与注意事项**

#### 实战 4：编写 NFTMarket ， 实现 Token 与 NFT 的兑换，掌握 NFT 市场上架、买卖、下架的实现。

- 挑战链接: https://decert.me/quests/abdbc346-8314-4394-8f97-8732780602ed

- [解题内容](./module-03/d04/)

- ***知识点:***
    - **NFT基础知识**
    - **NFT与Token之间的购买与兑换**


## 模块四：Foundry 开发工具

#### 练习 1： 完成 Foundry 基础知识挑战，用来测试对 Foundry 开发框架了解

- 挑战链接: https://decert.me/quests/3bca8f1f-df6b-469b-941e-79388ee280c6

- [解题内容](./module-04/d01/)

- ***知识点:***
    - **基础概念，没什么好说的**

#### 实战 2：使用 Foundry 部署和开源合约， 掌握使用 Foundry 进行合约开发、编译部署、开源验证全流程

- 挑战链接: https://decert.me/quests/7bd246d8-f0c3-45c0-a335-766505afdba9

- [解题内容](./module-04/d02/)

- ***知识点:***
    - **foundry编译，部署，开源功能**

#### 实战 3：使用 Foundry 进行测试。 测试 Bank 合约来熟悉 Foundry 各种作弊码的使用

- 挑战链接: https://decert.me/quests/b8cde6b2-bad4-4629-b73a-2d0dede4f347

- [解题内容](./module-04/d03/)

- ***知识点:***
    - **着重合约基础测试**

#### 实战 4：Foundry高阶测试， 掌握模糊测试，错误情况的测试以及事件的测试

- 挑战链接: https://decert.me/quests/08973815-3ebe-48d1-915e-7fc67c448763

- [解题内容](./module-04/d04/)

- ***知识点:***
    - **着重合约高级测试**

## 模块五：链钱包及前后端开发

#### 实战1. 给 代币银行TokenBank 合约添加前端界面，例如如何与链交互，掌握在前端调用合约。

- 挑战链接: https://decert.me/quests/56e455b3-901c-415d-90c0-a20759469cf9

- [解题内容](./module-05/d01/)

- ***知识点:***
    - **合约部署，本地节点使用，react+viem使用等等，内容很多**

#### 实战2. 在后端（使⽤ Viem.sh ）监听 NFTMarket 合约发生的事件（买卖记录）

- 挑战链接: https://decert.me/quests/b4698649-25b2-45ae-9bb5-23da0c49e491

- [解题内容](./module-05/d02/)

- ***知识点:***
    - **理解在后端通过 Viem.sh 事件，实时获取链上状态。**

#### 实战3. (使用 Viem)构建自己的命令行钱包， 来理解创建钱包账号、构造交易、签名交易、发送交易的全流程。

- 挑战链接: https://decert.me/quests/992dae0f-3bdf-4f03-9798-3427234fad95

- [解题内容](./module-05/d03/)

- ***知识点:***
    - **viem.js的使用：创建私钥，公开客户端，钱包客户端，eth转账，erc20转账，EIP1599发起交易等**

#### 实战 4. 实践操作 SafeWallet 多签钱包，理解多签的实现及使用

- 挑战链接: https://decert.me/quests/4d4d50ab-84ab-4289-ac67-e3839e078537

- [解题内容](./module-05/d04/)

- ***知识点:***
    - **理解 https://app.safe.global/ 网站的多签钱包基本原理、基础使用**

#### 实战 5. 实现一个简单的多签钱包，通过挑战理解合约钱包，多签的实现方式，理解底层 Call 调用。

- 挑战链接: https://decert.me/quests/f832d7a2-2806-4ad9-8560-a27ad8570c6f

- [解题内容](./module-05/d05/)

- ***知识点:***
    - **自己实现多签合约**

#### 实战 6. 为 NFT 市场 NFTMarket 项目添加前端，接入 AppKit 进行多钱包（尤其是 WalletConnect）前端登录

- 挑战链接: https://decert.me/quests/a1a9aff6-1788-4254-bc47-405cc529bbd1

- [解题内容](./module-05/d06/)

- ***知识点:***
    - **react+view+WCT使用**

#### 实战 7. 理解 EIP712 标准，尝试掌握用离线签名（Permit）的方式来进行 Token 的授权和白名单设计。

- 挑战链接: https://decert.me/quests/fc66ef6c-35db-4ee7-b11d-c3b2d3fa356a

- [解题内容](./module-05/d07/)

- ***知识点:***
    - **permit离线签名原理，两个应用场景（离线签名，离线白名单）**

#### 实战 8. 利用 Permit2 为所有的 Token 接入离线签名授权及转账功能，实践在前端发起支持 Permit2 的签名。

- 挑战链接: https://decert.me/quests/1fa3ecbc-a3cd-43ae-908e-661aac97bdc0

- [解题内容](./module-05/d08/)

- ***知识点:***
    - **未整理**

#### 实战 9：链上数据扫块：使用 Viem 索引链上 ERC20 转账数据并展示，掌握如果通过扫块的方式获取链上指定的数据。

- 挑战链接: https://decert.me/quests/ae220513-c0cb-4d9b-873a-caee1d4b358e

- [解题内容](./module-05/d09/)

- ***知识点:***
    - **viem扫块的使用，以及与数据库的结合**



