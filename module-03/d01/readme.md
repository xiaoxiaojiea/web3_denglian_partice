

### 基础内容
ERC20基础知识：
- 定义了一组通用接口，使得钱包、交易所、DApp 等可以统一地与代币交互。
- 标准函数
    - totalSupply()	返回代币总供应量
    - balanceOf(address account)	查询某地址的代币余额
    - transfer(address to, uint256 value)	发送代币到另一个地址
    - approve(address spender, uint256 value)	授权第三方地址可以花费自己的代币
    - allowance(address owner, address spender)	查看第三方地址还可以花费多少
    - transferFrom(address from, address to, uint256 value)	第三方地址代表 from 向 to 转账（前提是已授权）
- 标准事件
    - event Transfer(address indexed from, address indexed to, uint256 value)	代币转账事件
    - event Approval(address indexed owner, address indexed spender, uint256 value)

本节实战的内容与ERC20的关系
- ERC20是一个代币协议，他已经被官方实现了，在真实项目中我们基本上都是继承他来拿到我们自己的代币就可以了；
- 本节实战的目的是在不使用ERC20协议的情况些，自己写代码实现ERC20的基本功能。

重点内容：
- **除了原生代币之外的其他币种转账，基本都是对合约内部的balances进行地址的加减而已**
    - 原生币（ETH、BNB）使用 transfer / send / call 发送
    - 合约代币ERC20 / BEP20 等调用合约的 transfer 函数即可（内部其实就是加减balances）
- 授权余额的mapping组织形式是这样的：
    - mapping (address => mapping (address => uint256)) allowances; 
    - 解释：代币所有人 => 被批准使用人 => 使用代币数量

##### 题目1
编写 ERC20 token 合约, 实现以下功能：

- 设置 Token 名称（name）："BaseERC20"
- 设置 Token 符号（symbol）："BERC20"
- 设置 Token 小数位decimals：18
- 设置 Token 总量（totalSupply）:100,000,000
- 允许任何人查看任何地址的 Token 余额（balanceOf）
- 允许 Token 的所有者将他们的 Token 发送给任何人（transfer）；转帐超出余额时抛出异常(require),并显示错误消息 “ERC20: transfer amount exceeds balance”。
    - **除了原生代币之外的其他币种转账，基本都是对合约内部的balances进行地址的加减而已；**
- 允许 Token 的所有者批准某个地址消费他们的一部分Token（approve）
    - **代币所有人 => 被批准使用人 => 使用代币数量**
- 允许任何人查看一个地址可以从其它账户中转账的代币数量（allowance）
- 允许被授权的地址消费他们被授权的 Token 数量（transferFrom）；

- 转帐超出余额时抛出异常(require)，异常信息：“ERC20: transfer amount exceeds balance”
- 转帐超出授权数量时抛出异常(require)，异常消息：“ERC20: transfer amount exceeds allowance”。

注意：
- 在编写合约时，需要遵循 ERC20 标准，此外也需要考虑到安全性，确保转账和授权功能在任何时候都能正常运行无误。
- 代码模板中已包含基础框架，只需要在标记为“Write your code here”的地方编写你的代码。不要去修改已有内容！
- 希望你能用一段优雅、高效和安全的代码，完成这个挑战。
  
解析见代码：s01.sol

