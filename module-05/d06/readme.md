

### 基础知识


##### 题目1：DApp 接入 AppKit 登录
为 NFTMarket（module-03/d04） 项目添加前端，并接入 AppKit 进行前端登录，并实际操作使用 WalletConnect 进行登录（需要先安装手机端钱包）。
- 并在 NFTMarket 前端添加上架操作，切换另一个账号后可使用 Token 进行购买 NFT。


**题目分析**
将NFTMarket项目添加界面，界面可以登陆（使用WalletConnect），mint nft，上架nft，购买nft等功能


**NFTMarket后端合约项目部署**
- 创建项目：
    - mkdir c01 && cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt
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
- 写入src/script中的代码
- 部署
    - MyNFT: 0x9Fe64984744be783d40Bb01662e845b8544Ff474
    ```
    forge script script/MyNFT.s.sol:MyNFTScript \
    --rpc-url $ROPSTEN_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_KEY \
    -vvvv
    ```
    - MyToken: 0x48aB4cdd2bE0F059efE71c410F08216D3b656892
    ```
    forge script script/MyToken.s.sol:MyTokenScript \
    --rpc-url $ROPSTEN_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_KEY \
    -vvvv
    ```
    - NFTMarket: 0x56D9937BB622Ce9DaA00dC24F9374D332B9136EE
        - 要先设置MyToken合约地址到构造函数中
    ```
    forge script script/NFTMarket.s.sol:NFTMarketScript \
    --rpc-url $ROPSTEN_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_KEY \
    -vvvv
    ```

**给钱包中分别mint代币与nft**
- 到 https://sepolia.etherscan.io/address/0x9Fe64984744be783d40Bb01662e845b8544Ff474#writeContract 合约中手动给下边地址mint一些nft一会用于测试
    - 0xFeb5DDA8bbd9746B0b59b0b84964AF37E9172A8C

- 到 https://sepolia.etherscan.io/address/0x48aB4cdd2bE0F059efE71c410F08216D3b656892#writeContract 合约中给下边的地址转移一些代币
    - 0x5dda9dc9d70679cabae2dbd43b975e2baf2b9185
    - 转了 1000000000000000000000000 个代币 

**环境配置**
- 主钱包将自己的所有NFT授权给NFTMarket
    - https://sepolia.etherscan.io/address/0x9Fe64984744be783d40Bb01662e845b8544Ff474#writeContract
- 副钱包将自己的Token授权给NFTMarket
    - https://sepolia.etherscan.io/address/0x48aB4cdd2bE0F059efE71c410F08216D3b656892#writeContract

**NFTMarket前端React项目部署**

- 项目基础模板创建
    - npx create-react-app front_dapp
        - 速度慢的时候：npm config set registry https://registry.npmmirror.com
        - 然后再执行
    - npm start (记得访问不 http://192.168.0.100:3000/ 不然调不起来metamask)
    - 进入public/index.html，修改网站的标题和元描述
    - 进入src文件夹，删除App.test.js、logo.svg和setupTests.js文件。
    - 进入App.js文件，用以下模板替换其内容。
        ``` Javascript
        import './App.css';

        function App() {
            return (
                <h1>Hello World</h1>
            );
        }

        export default App;
        ```
    - 同时删除App.css的所有内容。但是，不要删除这个文件。
    - 然后就可以在这个模板上编写前端代码了。

- 编写代码












