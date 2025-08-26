
### 基础知识




##### 题目1
编写一个脚本（可以基于 Viem.js 、Ethers.js 或其他的库来实现）来模拟一个命令行钱包，钱包包含的功能有：
- 生成私钥、查询余额（可人工转入金额）
- 构建一个 ERC20 转账的 EIP 1559 交易
- 用 1 生成的账号，对 ERC20 转账进行签名
- 发送交易到 Sepolia 网络。


**ERC20代币**
- 我之前在sepolia部署过了一个代币，所以就不需要再去部署了：0x1a1Dd7994A1bA16BD2a58cd076EbeA69266587D6
- owner钱包地址是我的测试钱包：0xfeb5dda8bbd9746b0b59b0b84964af37e9172a8c
- 可以随时去mint，也可以做其他操作

**基于viem+readline-sync的命令行钱包**
创建文件夹
- mkdir cli_wallet && cd cli_wallet
- npm init -y
- 用国内镜像加速 npm install：npm config set registry https://registry.npmmirror.com
- npm install viem readline-sync dotenv

新建 .env 文件（保存 RPC 和你的钱包私钥）
- SEPOLIA_RPC_URL=xxx
- PRIVATE_KEY=xxx

新建 wallet.js 文件
- 写入内容
- 运行：node wallet.js


测试：
- 新建钱包
    - 地址: 0x9aeb2CEdbd477C12D19B94093A58b27B9074B611
    - 私钥: 0x80cfc82cfff894d3e47b963f6c31cf32f5dd3f2a4fb61ae8dd6e791629087527
- 登陆有ETH与ERC20代币的钱包
- 查看ETH，ERC20代币余额
- 发送一些ETH给 0x9aeb2CEdbd477C12D19B94093A58b27B9074B611 作为手续费，并且发给他一些ERC20代币
- 登陆钱包 0x9aeb2CEdbd477C12D19B94093A58b27B9074B611 
- 查看ETH，ERC20代币余额
- 发给一些ERC20代币给 0xfeb5dda8bbd9746b0b59b0b84964af37e9172a8c
- 检查余额


输出日至大概如下：

jie@jie:~/shj_other_ws/学习记录/web3课程02_登链/module-05/d03/cli_wallet$ node wallet.js
[dotenv@17.2.1] injecting env (2) from .env -- tip: ⚙️  suppress all logs with { quiet: true }
🚀 欢迎使用 CLI 钱包

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 1

===== 钱包切换 =====
1. 创建新钱包
2. 输入私钥切换钱包
请选择: 2
请输入私钥: ******************************************************************
✅ 钱包已切换到: 0xFeb5DDA8bbd9746B0b59b0b84964AF37E9172A8C

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 2
ETH 余额: 1.312865609892676715 ETH

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 3
ERC20 余额: 8491 PUSDT

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 4
请输入接收地址: 0x9aeb2CEdbd477C12D19B94093A58b27B9074B611
请输入转账数量(ETH): 0.001
✅ ETH 转账提交成功, hash: 0xc9808748d6b991a230e60284c9b3beec203703fd3a88df235a49561905971b7d

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 5
请输入接收地址: 0x9aeb2CEdbd477C12D19B94093A58b27B9074B611
请输入转账数量(整数): 20
✅ ERC20 转账提交成功, hash: 0x18ff016afb567bde85dfbef0259ba12238e5c0bff34057d05ba1fa6edac5e584

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 1

===== 钱包切换 =====
1. 创建新钱包
2. 输入私钥切换钱包
请选择: 2
请输入私钥: ******************************************************************
✅ 钱包已切换到: 0x9aeb2CEdbd477C12D19B94093A58b27B9074B611

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 2
ETH 余额: 0.001 ETH

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 3
ERC20 余额: 20 PUSDT

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 5
请输入接收地址: 0xfeb5dda8bbd9746b0b59b0b84964af37e9172a8c
请输入转账数量(整数): 10
✅ ERC20 转账提交成功, hash: 0x0d728d3f94d2c1dba6cb6e75896dd03ec90de0a7c98dd323295cf652f07e2385

===== CLI 钱包 =====
1. 切换钱包 / 创建钱包
2. 查看 ETH 余额
3. 查看 ERC20 余额
4. 转账 ETH
5. 转账 ERC20
0. 退出
请选择功能: 0



