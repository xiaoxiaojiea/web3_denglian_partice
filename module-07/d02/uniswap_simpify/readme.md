
# uniswap-v2深度解析

**目前只是浅浅的了解，后续要深入读取这份代码，并且写出一个带前端的uniswap**

源码参考：https://github.com/qiaopengjun5162/Uniswap-v2-08
博文参考：https://learnblockchain.cn/article/17355


## 项目分析

### 整体分析
Uniswap V2 是一个自动做市商（AMM）去中心化交易所。它由几个核心合约组成，分别负责：
- UniswapV2Factory 合约：是 Pair 的“制造厂”，负责生产和登记所有 Token 对
- WETH 合约：ERC20 包装器，让 ETH 能像普通代币一样在交易池中使用
- UniswapV2Router02 合约：外部用户交互入口，负责组装路径、计算滑点、调用 Pair 实际执行 swap 或 LP 操作。
- Multicall 合约：让多个操作（例如加流动性 + swap）一次性完成。
- AToken/BToken合约：测试的 ERC20 代币
- 添加流动性：把两种代币（比如 AToken 和 BToken）按比例存入交易池，获得 LP Token

### 详细分析
#### UniswapV2Factory 合约
**作用**：负责创建和管理所有交易对（Pair），Factory 是 Pair 的“制造厂”，负责生产和登记所有 Token 对。

**核心职责**：
- 保存每个交易对的地址 mapping(address => mapping(address => address)) public getPair;
- 部署新的交易对合约 function createPair(address tokenA, address tokenB)
- 记录所有 Pair 地址数组 address[] public allPairs;

#### WETH 合约
**作用**：将原生 ETH 封装为 ERC20 代币，方便在合约中统一处理。

**核心职责**：
- Solidity 中无法直接持有 ETH 作为 ERC20，因此 Uniswap 把 ETH 封装为 WETH（Wrapped ETH），基本原理：
```Solidity
function deposit() public payable {
    balanceOf[msg.sender] += msg.value;
}
function withdraw(uint wad) public {
    require(balanceOf[msg.sender] >= wad);
    balanceOf[msg.sender] -= wad;
    payable(msg.sender).transfer(wad);
}

```

#### UniswapV2Router02 合约
**作用**：Router 是外部用户交互入口，负责组装路径、计算滑点、调用 Pair 实际执行 swap 或 LP 操作。

**核心职责**：
- 添加流动性 addLiquidity() / addLiquidityETH()
- 移除流动性 removeLiquidity()
- 代币兑换 swapExactTokensForTokens()
- 计算兑换路径 getAmountsOut() / getAmountsIn()
- Router02 版本比 Router01 增加了 支持fee-on-transfer token 的兼容。

#### Multicall 合约
**作用**：Multicall 是性能增强工具，让多个操作（例如加流动性 + swap）一次性完成

**核心职责**：
- 把多个函数调用打包为数组，在链上一次执行：
```Solidity
function multicall(bytes[] calldata data) external returns (bytes[] memory results)
```
- 例如：
```Solidity
multicall([
  abi.encodeWithSelector(router.addLiquidity.selector, ...),
  abi.encodeWithSelector(router.swapExactTokensForTokens.selector, ...)
]);
```

#### AToken/BToken合约
**作用**：AToken / BToken 是用来测试的 ERC20 代币，没有额外逻辑，仅供流动性池使用。

#### 添加流动性
**作用**：用户把两种代币（比如 AToken 和 BToken）按比例存入交易池，获得 LP Token。

**流程**：
- 用户授权 Router 可以使用 A、B
- 调用 Router.addLiquidity(): 
    - Router 检查 Pair 是否存在，否则让 Factory 创建。
    - 把用户的 TokenA / TokenB 转入 Pair。
    - Pair 更新储备量（reserveA / reserveB）。
    - 发行等量 LP Token 给用户。
- 用户获得 LP Token（代表池中份额）。


## 重点知识
111

## 代码使用流程
- 记得配置env

### 代码部署

#### 部署 UniswapV2Factory 合约
部署脚本：
- forge build
- source .env
- 部署代码（部署时验证）： 0x538f2323aB718c57920b7cc6B087dbdE1831D398
```
forge script script/UniswapV2Factory.s.sol:UniswapV2FactoryScript \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

#### 部署 WETH9 合约
部署脚本：
- forge build
- source .env
- 部署代码（部署时验证）： 0x7c83EbA4ff92Ec42239649Cd81d12398bC3fA64D
```
forge script script/WETH9.s.sol:WETH9Script \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

#### 部署 UniswapV2Router02 合约
部署脚本：
- forge build
- source .env
- 部署代码（部署时验证）： 0x60bEa571aB13c681234fb8A144851789d23BD0a7
```
forge script script/UniswapV2Router02.s.sol:UniswapV2Router02Script \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

#### 部署 Multicall 合约
部署脚本：
- forge build
- source .env
- 部署代码（部署时验证）： 0xfdf8fc29D794329EAcc383CE8d003F665Ec33b5A
```
forge script script/Multicall.s.sol:MulticallScript \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

#### 部署 AToken 合约
部署脚本：
- forge build
- source .env
- 部署代码（部署时验证）： 0xD4D34eF3e785A8525D31a544635361062f670D8D
```
forge script script/AToken.s.sol:ATokenScript \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

#### 部署 BToken 合约
部署脚本：
- forge build
- source .env
- 部署代码（部署时验证）： 0xFDb5981e84d3EdC2115357262E81288D4Ed2d532
```
forge script script/BToken.s.sol:BTokenScript \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    -vvvv
```

### 代码使用

后续大概就是如下操作：

1，token分发给一个地址，然后为该地址授权给Router可以操作他们的代币；
2，添加 AToken ↔ BToken 流动性
3，添加 ETH ↔ ERC20 流动性
4，Swap AToken → BToken
5，Swap ETH → ERC20
6，查询 reserves
7，查询交易输出数量






