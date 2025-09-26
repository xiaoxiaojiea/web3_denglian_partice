

### 基础知识


##### 编写一个线性解锁（ Vesting） 合约
编写一个 Vesting 合约（可参考 OpenZepplin Vesting 相关合约）， 相关的参数有：
- beneficiary： 受益人
- 锁定的 ERC20 地址
- Cliff：12 个月
- 线性释放：接下来的 24 个月，从 第 13 个月起开始每月解锁 1/24 的 ERC20
- Vesting 合约包含的方法 release() 用来释放当前解锁的 ERC20 给受益人，Vesting 合约部署后，开始计算 Cliff ，并转入 100 万 ERC20 资产。
- 在 Foundry 包含时间模拟测试


**题目解析**
- 题目：
    - Cliff 12个月（锁仓12个月）
    - 接下来的 24 个月，从 第 13 个月起开始每月解锁 1/24 的 ERC20
    - release方法可以让受益人提取解锁的代币
    - 部署时开始计算 Cliff ，并转入 100 万 ERC20 资产

- 解析：
    - Cliff 12个月内释放代币数量为0；
    - 第13-36个月每个月释放 100万/24 个代币
    - 释放的代币允许受益人提取


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

- 详细内容见代码解析

