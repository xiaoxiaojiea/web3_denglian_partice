

### 基础知识


##### 题目1
在NFTMarket（module-03/d04） 合约中在上架（list）和买卖函数（buyNFT 及 tokensReceived）中添加相应事件，在后台监听上架和买卖事件，如果链上发生了上架或买卖行为，打印出相应的日志。

**NFTMarket功能分析**
- MyNFT (ERC721)：只管NFT的发行和转移。
    - mint()铸造：给地址to铸造一个nft;
    - transferFrom()转移：替代转账功能将tokenId从地址from转移到地址to;
- MyToken (ERC20)：提供购买用的代币，并支持“带数据转账”，为回调购买模式提供可能。
    - transfer()：sender向地址to转一定数量的coin
    - transferAndCall()（扩展功能）：该函数会调用Market合约的购买NFT功能，实现回调的方式购买NFT
- NFTMarket：作为交易撮合中心，管理上架与成交，能兼容普通购买和回调购买两种模式。
    - list() 上架：卖方将NFT转移到market合约，等同于挂到了市场上了；
    - buyNFT() 普通购买：在market购买
    - tokensReceived() 回调购买：直接在token中购买


**初始化foundry合约项目**
- mkdir NFTMarketProj && cd NFTMarketProj
- forge init --no-git
- wget https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/heads/master.zip -O oz.zip
- unzip oz.zip -d lib/
- mv lib/openzeppelin-contracts-master lib/openzeppelin-contracts
- 编辑 foundry.toml
```
[dependencies]
openzeppelin = "lib/openzeppelin-contracts"
```
- forge remappings > remappings.txt
- forge build
- forge test
- 然后就可以将NFTMarket代码往里面写了

**操作合约项目**
- 部署合约
    - MyToken
        - forge script script/MyToken.s.sol:MyTokenScript --fork-url http://localhost:8545 --private-key $LOCAL_ACCOUNT --broadcast
        - 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
        - 将 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 设置到NFTMarketScript的paymentToken中
    - MyNFT
        - forge script script/MyNFT.s.sol:MyNFTScript --fork-url http://localhost:8545 --private-key $LOCAL_ACCOUNT --broadcast
        - 0x610178dA211FEF7D417bC0e6FeD39F05609AD788
    - NFTMarket
        - forge script script/NFTMarket.s.sol:NFTMarketScript --fork-url http://localhost:8545 --private-key $LOCAL_ACCOUNT --broadcast
        - 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e
- 部署钱包LOCAL_ACCOUNT给其他一些钱包发送一些MyToken
    - 查看某个钱包MyToken余额
    ```
    cast call \
        0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
        "balanceOf(address)(uint256)" \
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
        --rpc-url http://127.0.0.1:8545
    ```
    - to 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    ```
    cast send \
        0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
        "transfer(address,uint256)(bool)" \
        0x70997970C51812dc3A010C7d01b50e0d17dc79C8 \
        10000000000000000000000 \
        --private-key $LOCAL_ACCOUNT \
        --rpc-url http://127.0.0.1:8545
    ```
    - to 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
    ```
    cast send \
        0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
        "transfer(address,uint256)(bool)" \
        0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC \
        10000000000000000000000 \
        --private-key $LOCAL_ACCOUNT \
        --rpc-url http://127.0.0.1:8545
    ```
- 部署钱包mint3个nft
    - 连续执行3遍就可以了
    ```
    cast send 0x610178dA211FEF7D417bC0e6FeD39F05609AD788 \
        "mint(address)" \
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
        --private-key $LOCAL_ACCOUNT \
        --rpc-url http://127.0.0.1:8545
    ```
    - 将nft授权给NFTMarket
    ```
    cast send 0x610178dA211FEF7D417bC0e6FeD39F05609AD788 \
        "setApprovalForAll(address,bool)" \
        0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e true \
        --private-key $LOCAL_ACCOUNT \
        --rpc-url http://127.0.0.1:8545
    ```
    - 验证授权
    ```
    cast call 0x610178dA211FEF7D417bC0e6FeD39F05609AD788 \
        "isApprovedForAll(address,address)(bool)" \
        0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e \
        --rpc-url http://127.0.0.1:8545
    ```

**编写监听脚本**
- 演示完整项目的创建与运行
    - mkdir hello_viem
    - cd hello_viem
    - npm init -y
    - 安装依赖：npm install viem
    - 用 TypeScript，再加：
        - npm install -D typescript ts-node @types/node
        - npx tsc --init
    - 新建 src/init_test.ts
        - 写入内容
    - 进入src运行：npx ts-node init_test.ts
        - 然后就可以看到输出

- 编写监听脚本init_test.ts
- 启动监听脚本：npx ts-node init_test.ts


**操作上架，下架，购买**
- owner上架
    - 上架0号NFT：
        - 上架命令：
        ```
        cast send 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e \
            "list(address,uint256,uint256)" \
            0x610178dA211FEF7D417bC0e6FeD39F05609AD788 0 10000000000000000000 \
            --private-key $LOCAL_ACCOUNT \
            --rpc-url http://127.0.0.1:8545
        ```
        - 监听结果：🟢 Listed: NFT 0 from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 at price 10000000000000000000 (contract 0x610178dA211FEF7D417bC0e6FeD39F05609AD788)
    - 上架1号NFT：
        - 上架命令：
        ```
        cast send 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e \
            "list(address,uint256,uint256)" \
            0x610178dA211FEF7D417bC0e6FeD39F05609AD788 1 90000000000000000000 \
            --private-key $LOCAL_ACCOUNT \
            --rpc-url http://127.0.0.1:8545
        ```
        - 监听结果：🟢 Listed: NFT 1 from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 at price 90000000000000000000 (contract 0x610178dA211FEF7D417bC0e6FeD39F05609AD788)
    - 上架2号NFT：
        - 上架命令：
        ```
        cast send 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e \
            "list(address,uint256,uint256)" \
            0x610178dA211FEF7D417bC0e6FeD39F05609AD788 2 1000000000000000000 \
            --private-key $LOCAL_ACCOUNT \
            --rpc-url http://127.0.0.1:8545
        ```
        - 监听结果：🟢 Listed: NFT 2 from 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 at price 1000000000000000000 (contract 0x610178dA211FEF7D417bC0e6FeD39F05609AD788)

- 一个账户直接市场购买0：
    - 该账户授权Token给NFTMarket：
    ```
    cast send 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
        "approve(address,uint256)" \
        0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e 10000000000000000000000 \
        --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
        --rpc-url http://127.0.0.1:8545
    ```
    - 该账户购买NFT-0
    ```
    cast send 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e \
        "buyNFT(address, uint256)" \
        0x610178dA211FEF7D417bC0e6FeD39F05609AD788 0 \
        --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d \
        --rpc-url http://127.0.0.1:8545
    ```
    - 输出：🛒 Bought: NFT 0 from 0x610178dA211FEF7D417bC0e6FeD39F05609AD788, buyer 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, price 10000000000000000000
    
- 一个账户直接回调购买1：
    - 先拿到编码参数：（encodeNFTData 是一个纯函数（pure/view），不改变链上状态，不能用 cast send（那是用来发送交易改变链上状态的）。用 cast call 来读取返回值。）
    ```
    cast call 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
        "encodeNFTData(address, uint256)(bytes)" \
        0x610178dA211FEF7D417bC0e6FeD39F05609AD788 1 \
        --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a \
        --rpc-url http://127.0.0.1:8545
    ```
    - 输出：0x000000000000000000000000610178da211fef7d417bc0e6fed39f05609ad7880000000000000000000000000000000000000000000000000000000000000001
    - 调用回调购买
    ```
    cast send 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
        "transferAndCall(address, uint256, bytes)(bool)" \
        0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e \
        90000000000000000000  \
        0x000000000000000000000000610178da211fef7d417bc0e6fed39f05609ad7880000000000000000000000000000000000000000000000000000000000000001 \
        --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a \
        --rpc-url http://127.0.0.1:8545
    ```
    - 输出：🛒 Bought: NFT 1 from 0x610178dA211FEF7D417bC0e6FeD39F05609AD788, buyer 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC, price 90000000000000000000

- 下架2：
    - owner下架2号
    ```
    cast send 0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e \
        "delist(address, uint256)" \
        0x610178dA211FEF7D417bC0e6FeD39F05609AD788 2 \
        --private-key $LOCAL_ACCOUNT \
        --rpc-url http://127.0.0.1:8545
    ```
    - 输出：⚪️ Delisted: NFT 2 by 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (contract 0x610178dA211FEF7D417bC0e6FeD39F05609AD788)

