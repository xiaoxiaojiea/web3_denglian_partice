

##### 题目#1
编写 NFTMarket 合约：（稍微修改了一下题目，更清晰）
- 支持 设定任意ERC20代币 的 任意价格来 上架NFT
- 支持 支付ERC20 购买指定的NFT

要求测试内容：
- 上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
- 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
- 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
- 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓

提交内容要求
- 使用 foundry 测试和管理合约；
- 提交 Github 仓库链接到挑战中；
- 提交 foge test 测试执行结果txt到挑战中；

解题：参考 module-03/d04 中的代码，踢除了回调购买
- 创建项目：
    - mkdir c01 
    - cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt

- 安装库：
    - wget https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/heads/master.zip -O oz.zip
    - unzip oz.zip -d lib/
    - mv lib/openzeppelin-contracts-master lib/openzeppelin-contracts
    - rm oz.zip
- 配置 foundry.toml
    - 写入
    ```yaml
    [dependencies]
    openzeppelin = "lib/openzeppelin-contracts"
    ```
    - 生成 Remappings: forge remappings > remappings.txt

- 本地测试环境准备
    - 在.env中设置自己的参数
    - source .env

- src中准备代码
    - 修改自之前的NFTMarket的所有代码

- test代码准备:
    - ListNFT.t.sol: 上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
    - BuyNFT.t.sol: 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
    - MarketFuzzTest.t.sol: 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    - Invariant.t.sol: 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    - 注释都在代码中了
