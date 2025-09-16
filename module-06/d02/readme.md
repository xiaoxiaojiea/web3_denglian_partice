
### 基础知识
目前来看只有减少冗余操作，减少链上数据存储等操作


##### 题目#1：优化 NFTMarket 的 Gas 表现
- 先查看先前 NFTMarket（module-03/d04） 的各函数消耗，测试用例的 gas report 记录到 gas_report_v1.md
- 尝试优化 NFTMarket 合约，尽可能减少 gas ，测试用例 用例的 gas report 记录到 gas_report_v2.md



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

- 代码转移：将（module-03/d04）中的代码转移到本foundry工程中（可以从 module-04/d04 中拷贝 ）
    - 拷贝过来 BuyNFT.t.sol 因为没有test的话没法输出gas-report

- 拿到原始代码测试用例的 gas_report_v1.md 
    - forge test --gas-report > gas_report_v1.md

- 优化 NFTMarket 合约，其他内容均不要修改
    - 分析 gas_report_v1.md 可知NFTMarket 合约部署成本大约 1,257,881 gas，函数消耗主要在 
        - list：≈154k
        - buyNFT：31k–88k（取决于路径）
    - 优化1：减少存储读写
        - 问题：目前你的 list / buyNFT / delist 都是这样取结构体：Listing memory item = listings[nftAddress][tokenId];
            - 导致：1）从 storage 加载一个 struct → 多个 SLOAD 操作；2）再赋值到 memory
        - 优化：可以只按需读字段，避免整个 struct 复制
            - delist: 
                - 将 Listing memory item = listings[nftAddress][tokenId]; 修改为下边的版本
                - Listing storage item = listings[nftAddress][tokenId];
            - buyNFT: 
                - 将 Listing memory listing = listings[nftAddress][tokenId]; 修改为下边的版本
                - Listing storage listing = listings[nftAddress][tokenId];
            - 可以对比两个 gas_report 看到 buyNFT 的gas降低了一部分
            - 原理：因为 listings 中有结构体会存储在storage中，使用的时候如果加载到memory中是要进行 storage到memory赋值的
        - 优化：缩短错误信息字符串，每个 require("...") 的字符串会增加部署成本。比如 "Price must be > 0"，可以缩短为 "PRICE0"
            - "Price must be > 0" 修改为 "PRICE0"
            - "ERC20 transfer failed" 修改为 "transfer failed"
            - 可能字符串减少的太少，gas没看到变化
        - 事件参数压缩：事件字段太多会增加 gas（存储到日志里）
            - 例如：event Bought(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, address priceToken, uint256 price);
                - 3 个 indexed，再加 2 个非索引字段 → 5 个 topic/data
                - 如果减少 indexed 数量（比如只保留 buyer、nftContract、tokenId），gas 会明显下降。
            - Listed，Bought都减少了后边两个参数
        - 结构体精简：Listing 里保存了 tokenAddress，但其实它就是外层 key nftAddress，是冗余的。

- 拿到优化后代码测试用例的 gas_report_v2.md 
    - forge test --gas-report > gas_report_v2.md
    - 然后去对比就会发现减少了一部分


