
### 基础知识

**默克尔树用于白名单验证**
- 让拥有白名单的用户领取空投最简单的方法就是将白名单用户的地址存在合约中然后调用者一一对比，但是这样存储的数据太大gas很高，所以需要使用某种方式来优化gas；
- Merkle Tree 只需要存储 一个 root（32 bytes），就能验证任意用户是否在白名单中
- Merkle Tree 构建过程
    - 叶子节点 (Leaf)：把每个白名单用户的地址 keccak256(abi.encodePacked(address)) 得到一个哈希值。
        - leaf_i = keccak256(address_i)
    - 两两合并 (Pairing)：把相邻两个叶子拼接，再哈希，生成父节点
        - parent = keccak256(left || right)
    - 不断合并：重复上一步，直到只剩下一个根节点
        - Merkle Root，这个 root 存到合约里
- 验证过程（Proof 验证）：假设用户 Alice 想证明自己在白名单中
    - Alice 提交：
        - 自己的地址 address(Alice)
        - 对应的 Merkle Proof（路径节点哈希数组）
    - 合约验证：
        - 先计算叶子哈希：leaf = keccak256(address(Alice))
        - 然后依次和 proof 中的节点合并，计算上层哈希
            ```
            hash_1 = keccak256(leaf || proof[0])
            hash_2 = keccak256(hash_1 || proof[1])
            ...
            root_candidate = hash_last
            ```
        - 如果 root_candidate == merkleRoot（合约存的 root），则说明 Alice 在白名单中。
- **例子: 白名单用户：A, B, C, D**
    - 构建
        - 叶子：
            ```
            hA = keccak256(A)
            hB = keccak256(B)
            hC = keccak256(C)
            hD = keccak256(D)
            ```
        - 父节点：
            ```
            hAB = keccak256(hA || hB)
            hCD = keccak256(hC || hD)
            ```
        - Root：
            ```
            root = keccak256(hAB || hCD)
            ```
    - 验证
        - 她的 leaf 是 hA
        - Proof 就是 [hB, hCD]
        - 验证过程：
            ```
            keccak256(hA || hB) = hAB
            keccak256(hAB || hCD) = root
            ```
        - 与合约存的 root 一致，验证成功。


**ERC20 Permit 授权**
章节 （module-05/d07） 演示过 Permit 授权的使用方法，他其实就是用户线下签好名，这个签名信息可以由别人提交到链上，然后要使用 Permit 功能的合约代币需要继承 ERC20Permit 。

**Multicall + Delegatecall + call**
- 还有一个节省gas的方法：将多个合约调用封装在一个交易中，使用 Multicall 
- Multicall函数中可以直接使用 call（不保留上下文调用，用于读调用） 或者 Delegatecall（保留上下文调用，用于写调用） 调用真实函数；



##### 题目#1 组合使用 MerkleTree 白名单、 Permit 授权 及 Multicall
实现一个 AirdopMerkleNFTMarket 合约(假定 Token、NFT、AirdopMerkleNFTMarket 都是同一个开发者开发)，功能如下：
- 基于 Merkel 树验证某用户是否在白名单中
- 在白名单中的用户可以使用上架（和之前的上架逻辑一致）指定价格的优惠 50% 的Token 来购买 NFT， Token 需支持 permit 授权。

要求使用 multicall( delegateCall 方式) 一次性调用两个方法：
- permitPrePay() : 调用token的 permit 进行授权
- claimNFT() : 通过默克尔树验证白名单，并利用 permitPrePay 的授权，转入 token 转出 NFT 。

请贴出你的代码 github ，代码需包含合约，multicall 调用封装，Merkel 树的构建以及测试用例。


**工作流程**
- 前端生成 Merkle proof 证明用户在白名单中。
- 用户签名 ERC20 permit，允许市场合约转账代币。
- 前端通过 multicall 一次性调用：
    - permitPrePay → 授权 token
    - claimNFT → 验证白名单 + 扣费 + mint NFT
- 用户支付半价 token 并获得 NFT。


**项目解答**
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






