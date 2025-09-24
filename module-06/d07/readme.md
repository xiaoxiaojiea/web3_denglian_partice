
### 基础知识



##### 题目：编写一个可升级的 NFT Market 合约
- 编写一个可升级的 ERC721 合约.
- 实现⼀个可升级的 NFT 市场合约：
    - 实现合约的第⼀版本和这个挑战 的逻辑一致。
    - 逻辑合约的第⼆版本，加⼊离线签名上架 NFT 功能⽅法（签名内容：tokenId， 价格），实现⽤户⼀次性使用 setApproveAll 给 NFT 市场合约，每个 NFT 上架时仅需使⽤签名上架。
    - 部署到测试⽹，并开源到区块链浏览器，在你的Github的 Readme.md 中备注代理合约及两个实现的合约地址。
- 要求：
    - 包含升级的测试用例（升级前后的状态保持一致）
    - 包含运行测试用例的日志。


**特殊解答：使用ERC20给出一个代理合约实例（因为之前没有写过，这里补充一个）**
- 代码见 c01，在remix上边验证的，其中的代理合约怎么调用是一个知识点
- remix上边的代理合约怎么调用：
    - 部署 LogicV1
    - 输入参数部署 SimpleProxy
    - **拿着部署的SimpleProxy地址，选择LogicV1合约，点击At Address拿到LogicV1-proxy合约**
        - 这样拿到的合约就是可以直接调用逻辑合约的代理合约了
        - 这个时候在这个合约里边做一些mint操作（保留根据，这样更换V2逻辑合约的时候才能验证对不对）
    - 部署 LogicV2
    - 回到SimpleProxy合约，修改逻辑合约地址
    - **拿着修改后逻辑合约地址的SimpleProxy地址，选择LogicV2合约，点击At Address拿到LogicV2-proxy合约**
        - 然后再点击该合约的信息检查一下与LogicV1-proxy之前操作的数据应该对上了，说明升级成功

**题目解答：编写一个可升级的 ERC721 合约**
- 代码见 c02，在remix上边验证的，其中的代理合约怎么调用是一个知识点
- remix上边的代理合约怎么调用：
    - 部署 ERC721LogicV1
    - 输入参数部署 SimpleProxy
    - **拿着部署的SimpleProxy地址，选择ERC721LogicV1合约，点击At Address拿到ERC721LogicV1-proxy合约**
        - 这样拿到的合约就是可以直接调用逻辑合约的代理合约了
        - 这个时候在这个合约里边做一些mint操作（保留根据，这样更换V2逻辑合约的时候才能验证对不对）
        - 记得切换非管理员身份mint，因为这里把管理员身份限制为只能够更新代理，不允许调用其他方法了
    - 部署 ERC721LogicV2
    - 回到SimpleProxy合约，修改逻辑合约地址
    - **拿着修改后逻辑合约地址的SimpleProxy地址，选择ERC721LogicV2合约，点击At Address拿到ERC721LogicV2-proxy合约**
        - 然后再点击该合约的信息检查一下与ERC721LogicV2-proxy之前操作的数据应该对上了，说明升级成功

**题目解答：实现⼀个可升级的 NFT 市场合约**
- 项目创建
    - mkdir c03 && cd c03
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt
    - wget https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/heads/master.zip -O oz.zip
        - unzip oz.zip -d lib/
        - mv lib/openzeppelin-contracts-master lib/openzeppelin-contracts
        - rm oz.zip
    - 生成 Remappings: forge remappings > remappings.txt
    - 编写代码

- NFT，Token，MarketV1，MarketV2，Proxy以及Test合约
    - MarketV1与 module-03/d04 中的类似；
    - MarketV2中添加了离线签名函数
    - Proxy就是基本的代理函数合约
    - 直接运行test即可：forge test -vvvv
        - 运行日至如下：


jie@jie:~/shj_other_ws/学习记录/web3课程02_登链/module-06/d07/c03$ forge test -vvvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 2 tests for test/NFTMarket.t.sol:NFTMarketUpgradeTest
[PASS] testListWithSig() (gas: 2291191)
Traces:
  [2295991] NFTMarketUpgradeTest::testListWithSig()
    ├─ [0] VM::startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
    │   └─ ← [Return] 
    ├─ [2010725] → new NFTMarketV2@0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
    │   └─ ← [Return] 10043 bytes of code
    ├─ [9205] SimpleProxy::upgradeTo(NFTMarketV2: [0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9])
    │   ├─ emit Upgraded(implementation: NFTMarketV2: [0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9])
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
    │   └─ ← [Return] 
    ├─ [25124] MyNFT::setApprovalForAll(SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], true)
    │   ├─ emit ApprovalForAll(owner: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, operator: SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], approved: true)
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::sign("<pk>", 0x24ed2fa320652f48712eeb3ddf46b5920295298609a0b4a5ba2f27a3958e01aa) [staticcall]
    │   └─ ← [Return] 28, 0x69731b657c364faf5ea825e19ae5d3d8267e473de5279d45535c2f9141238d36, 0x319dda09ce55282593dc4d8bccd4b9ab3e3d2c48a509600d18e75f95c206253c
    ├─ [3000] PRECOMPILES::ecrecover(0x24ed2fa320652f48712eeb3ddf46b5920295298609a0b4a5ba2f27a3958e01aa, 28, 47696225596879528231882202287050795383792082253714604300251168927107082587446, 22442229414822743286264801482043894254312690818851194441732332324670318978364) [staticcall]
    │   └─ ← [Return] 0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
    ├─ [0] VM::startPrank(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
    │   └─ ← [Return] 
    ├─ [143010] SimpleProxy::fallback(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0, 100, 0x69731b657c364faf5ea825e19ae5d3d8267e473de5279d45535c2f9141238d36319dda09ce55282593dc4d8bccd4b9ab3e3d2c48a509600d18e75f95c206253c1c)
    │   ├─ [141900] NFTMarketV2::listWithSig(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0, 100, 0x69731b657c364faf5ea825e19ae5d3d8267e473de5279d45535c2f9141238d36319dda09ce55282593dc4d8bccd4b9ab3e3d2c48a509600d18e75f95c206253c1c) [delegatecall]
    │   │   ├─ [3000] PRECOMPILES::ecrecover(0x24ed2fa320652f48712eeb3ddf46b5920295298609a0b4a5ba2f27a3958e01aa, 28, 47696225596879528231882202287050795383792082253714604300251168927107082587446, 22442229414822743286264801482043894254312690818851194441732332324670318978364) [staticcall]
    │   │   │   └─ ← [Return] 0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
    │   │   ├─ [3049] MyNFT::ownerOf(0) [staticcall]
    │   │   │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    │   │   ├─ [1264] MyNFT::isApprovedForAll(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9]) [staticcall]
    │   │   │   └─ ← [Return] true
    │   │   ├─ [36808] MyNFT::transferFrom(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], 0)
    │   │   │   ├─ emit Transfer(from: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, to: SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], tokenId: 0)
    │   │   │   └─ ← [Stop] 
    │   │   ├─ emit Listed(nftAddress: MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], tokenId: 0, seller: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, price: 100)
    │   │   └─ ← [Stop] 
    │   └─ ← [Return] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [2717] SimpleProxy::fallback(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0) [staticcall]
    │   ├─ [1634] NFTMarketV2::listings(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0) [delegatecall]
    │   │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100, MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3]
    │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100, MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3]
    ├─ [0] VM::startPrank(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC)
    │   └─ ← [Return] 
    ├─ [0] VM::expectRevert(custom error 0xf4844814)
    │   └─ ← [Return] 
    ├─ [9840] SimpleProxy::fallback(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0, 100, 0x69731b657c364faf5ea825e19ae5d3d8267e473de5279d45535c2f9141238d36319dda09ce55282593dc4d8bccd4b9ab3e3d2c48a509600d18e75f95c206253c1c)
    │   ├─ [8717] NFTMarketV2::listWithSig(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0, 100, 0x69731b657c364faf5ea825e19ae5d3d8267e473de5279d45535c2f9141238d36319dda09ce55282593dc4d8bccd4b9ab3e3d2c48a509600d18e75f95c206253c1c) [delegatecall]
    │   │   ├─ [3000] PRECOMPILES::ecrecover(0x24ed2fa320652f48712eeb3ddf46b5920295298609a0b4a5ba2f27a3958e01aa, 28, 47696225596879528231882202287050795383792082253714604300251168927107082587446, 22442229414822743286264801482043894254312690818851194441732332324670318978364) [staticcall]
    │   │   │   └─ ← [Return] 0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8
    │   │   ├─ [1049] MyNFT::ownerOf(0) [staticcall]
    │   │   │   └─ ← [Return] SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9]
    │   │   └─ ← [Revert] revert: Signer not owner
    │   └─ ← [Revert] revert: Signer not owner
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    └─ ← [Stop] 

[PASS] testUpgradeKeepsState() (gas: 2242653)
Traces:
  [2247453] NFTMarketUpgradeTest::testUpgradeKeepsState()
    ├─ [0] VM::startPrank(0x70997970C51812dc3A010C7d01b50e0d17dc79C8)
    │   └─ ← [Return] 
    ├─ [25124] MyNFT::setApprovalForAll(SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], true)
    │   ├─ emit ApprovalForAll(owner: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, operator: SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], approved: true)
    │   └─ ← [Stop] 
    ├─ [118888] SimpleProxy::fallback(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0, 100)
    │   ├─ [111308] NFTMarketV1::list(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0, 100) [delegatecall]
    │   │   ├─ [3049] MyNFT::ownerOf(0) [staticcall]
    │   │   │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
    │   │   ├─ [36808] MyNFT::transferFrom(0x70997970C51812dc3A010C7d01b50e0d17dc79C8, SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], 0)
    │   │   │   ├─ emit Transfer(from: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, to: SimpleProxy: [0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9], tokenId: 0)
    │   │   │   └─ ← [Stop] 
    │   │   ├─ emit Listed(nftAddress: MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], tokenId: 0, seller: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, price: 100)
    │   │   └─ ← [Stop] 
    │   └─ ← [Return] 
    ├─ [2717] SimpleProxy::fallback(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0) [staticcall]
    │   ├─ [1634] NFTMarketV1::listings(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0) [delegatecall]
    │   │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100, MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3]
    │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100, MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3]
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::startPrank(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266)
    │   └─ ← [Return] 
    ├─ [2010725] → new NFTMarketV2@0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
    │   └─ ← [Return] 10043 bytes of code
    ├─ [5105] SimpleProxy::upgradeTo(NFTMarketV2: [0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9])
    │   ├─ emit Upgraded(implementation: NFTMarketV2: [0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9])
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [2717] SimpleProxy::fallback(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0) [staticcall]
    │   ├─ [1634] NFTMarketV2::listings(MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3], 0) [delegatecall]
    │   │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100, MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3]
    │   └─ ← [Return] 0x70997970C51812dc3A010C7d01b50e0d17dc79C8, 100, MyNFT: [0x5FbDB2315678afecb367f032d93F642f64180aa3]
    └─ ← [Stop] 

Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 5.51ms (3.53ms CPU time)

Ran 1 test suite in 1.06s (5.51ms CPU time): 2 tests passed, 0 failed, 0 skipped (2 total tests)














































使用代理合约实现

- 项目创建
    - mkdir c01 && cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt
    - wget https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/heads/master.zip -O oz.zip
        - unzip oz.zip -d lib/
        - mv lib/openzeppelin-contracts-master lib/openzeppelin-contracts
        - rm oz.zip
    - 生成 Remappings: forge remappings > remappings.txt









