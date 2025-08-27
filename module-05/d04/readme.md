

### 基础知识

使用https://app.safe.global/网站的多签钱包基本原理：
- 多个钱包一起创建一个多签钱包，然后这个钱包没有私钥，但是这个钱包可以发起直接调用智能合约的交易，然后这个交易需要多个创建这个多签钱包的钱包确认，确认之后才会将该交易发送到链上；
- 具体例子见下边的习题；


##### 题目#1：实践 SafeWallet 多签钱包

在 Safe Wallet 支持的测试网上创建一个 2/3 多签钱包。然后：
- 往多签中存入自己创建的任意 ERC20 Token。
- 从多签中转出一定数量的 ERC20 Token。

- 把 Bank 合约的管理员设置为多签。
- 请贴 Safe 的钱包链接。
- 5. 从多签中发起， 对 Bank 的 withdraw 的调用

ERC20测试设置：
- 进入 https://safe.global/wallet ， 连接钱包，点击创建，Create new Safe Account页面选择sepolia网络，
- Signers and confirmations页面设置三个钱包，下方的Threshold选择2
- 支付sepolia创建多签钱包，钱包地址: 0x462dDFEAF67Fc0e6c00AE6e38eCf1206EEad3Ba7 
- 将我的代币: 0x1a1Dd7994A1bA16BD2a58cd076EbeA69266587D6 , 转一些给多签钱包，转账hash：0x2540337b36d86953ca4e0b462e34ce325b8729dba009e3ea8cba4b94d091f5e4

Bank测试设置：
- 部署一下Bank到sepolia: 0x3dE421ed2F9780932383D5e7Df162190067F2Fda
    ```
    forge script script/bank.s.sol:BankScript \
    --rpc-url $ROPSTEN_RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_KEY \
    -vvvv
    ```
- 首先去sepolia转换owner给多签钱包，然后再去多签钱包做操作
- 连接一个你是该 Safe签名者（Owner） 的钱包，点击 “New transaction” -> “Interact with contracts”。
- 填写合约地址与abi，然后选择调用的方法，填写提取user的eth，发起调用，然后多个账号确认交易，并且执行该交易
- 然后就可以发现你bank合约中的sepolia已经到多签钱包中了
- 然后发起转账，多个钱包确认之后就可以将刚才的sepolia转到自己钱包中了


