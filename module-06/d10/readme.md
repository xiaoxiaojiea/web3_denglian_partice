

### 基础知识



##### 题目
先实现一个 Bank 合约， 用户可以通过 deposit() 存款， 然后使用 ChainLink Automation 、Gelato 或 OpenZepplin Defender Action 实现一个自动化任务， 自动化任务实现：当 Bank 合约的存款超过 x (可自定义数量)时， 转移一半的存款到指定的地址（如 Owner）。



**题目解答**
- 项目创建
    - mkdir c01 && cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt
    - wget https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/heads/master.zip -O oz.zip
        - unzip oz.zip -d lib/
        - mv lib/openzeppelin-contracts-master lib/openzeppelin-contracts
        - rm oz.zip
    - wget https://github.com/smartcontractkit/chainlink-brownie-contracts/archive/67887b84d3add02a25ef4145fc014e2f549509da.zip -O cl.zip
        - unzip cl.zip -d lib/
        - mv lib/chainlink-brownie-contracts-67887b84d3add02a25ef4145fc014e2f549509da lib/chainlink-brownie-contracts
        - rm cl.zip
        - 直接修改remappings.txt文件：
            - 添加：@chainlink/=lib/chainlink-brownie-contracts/

- 教程：https://blog.chain.link/how-to-automate-smart-contract-execution-using-chainlink-automation-zh/

- 编写：
    - 编写合约 Bank.sol
    - 部署合约到sepolia：0x3d76185610385Dc78b26440Eb01B1Fc2b0F92b1D
        ```
        forge script script/Bank.s.sol:BankScript \
        --rpc-url $ROPSTEN_RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        --verify \
        --etherscan-api-key $ETHERSCAN_KEY \
        -vvvv
        ```
    - 注意必须开源代码才可以在chainlink上验证通过

- 注意事项：Bank.sol
    - 文档：https://blog.chain.link/how-to-automate-smart-contract-execution-using-chainlink-automation-zh/
    - 导入 chainlink 包；
    - 继承 AutomationCompatibleInterface 接口；
        - 接口要求实现 checkUpkeep 和 performUpkeep，用于 Chainlink 自动化任务（定时/条件触发）。
        - 代码调用逻辑注释在代码中，可以自己查看
    - **注意**：创建的 https://automation.chain.link/sepolia/90942017778516977849142128343579715496036897790700181597494158532781069694000 中需要存入 link 代币（sepolia），不然无法正常执行；



