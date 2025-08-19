
### 基础知识



#### 题目1：给 TokenBank（module-03/d02） 添加前端界面：
- 显示当前 Token 的余额，并且可以存款(点击按钮存款)到 TokenBank
- 存款后显示用户存款金额，同时支持用户取款(点击按钮取款)。


##### 合约部署内容

**初始化foundry合约项目**
- mkdir tokenBankProj && cd tokenBankProj
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
- 然后就可以将tokenBank代码往里面写了

**启动anvil**

**编写智能合约**

MyToken
- 编写 src/MyToken.sol
- 编写 script/MyToken.s.sol
- 编译：forge build
- 仅部署指定合约：forge script script/MyToken.s.sol:MyTokenScript --fork-url http://localhost:8545 --private-key $LOCAL_ACCOUNT --broadcast
    - 0x5FbDB2315678afecb367f032d93F642f64180aa3

TokenBank
- 编写 src/TokenBank.sol
- 编写 script/TokenBank.s.sol
    - 修改 tokenAddress = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
- 编译：forge build
- 仅部署指定合约：forge script script/TokenBank.s.sol:TokenBankScript --fork-url http://localhost:8545 --private-key $LOCAL_ACCOUNT --broadcast
    - 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

**智能合约功能分析**

MyToken
- 一个ERC20的Token，总量 600000*1e18 个mint给了LOCAL_ACCOUNT账户

TokenBank
- 用户存取MyToken的合约

##### 前端相关

**初始化react项目**
- npx create-react-app front_page && cd front_page
- npm start (记得访问 http://192.168.0.100:3000/ 不然调不起来metamask)
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
- 然后就可以在这个模板上编写前端代码了


**钱包添加foundry本地网络与钱包环境配置**

- 添加网络内容：
```Javascript
export const foundry = /*#__PURE__*/ defineChain({
  id: 31_337,
  name: 'Foundry',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: {
      http: ['http://127.0.0.1:8545'],
      webSocket: ['ws://127.0.0.1:8545'],
    },
  },
})
```
- 添加私钥：
    - 将LOCAL_ACCOUNT的私钥导入metamask，然后刷新代币列表应该就可以看到eth了
    - 然后在导入上边部署的代币MTK 0x5FbDB2315678afecb367f032d93F642f64180aa3 就可以看到该账户下的金额了
- 转账：
    - 给一些钱包账户转账一些MTK 0x5FbDB2315678afecb367f032d93F642f64180aa3 代币
        - 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
            - 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        - 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC
            - 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
    - 然后里边都有我们自己的代币了，开始下边的操作

**界面编写**
- 见 App.js
- 如果弹出的钱包是okx而不是metamask，可以先把okx扩展程序禁用

