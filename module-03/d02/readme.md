

### 基础知识

用户调用合约进行存款与取款时的逻辑是不同的
- 存款的时候，相当于是合约要将sender的代币转移到自己合约地址中，所以合约需要被sender授权可以操作自己的代币；
    - 函数：token.transferFrom(msg.sender, address(this), amount);
        - 将代币token，从sender地址，转移到this地址，数量为amount
        - **代替别人转出代币（需授权）**
- 取款的时候，相当于是合约将自己的代币转移到sender地址中，此时是合约自己操作自己的代币，所以无需授权；
    - 函数：token.transfer(msg.sender, amount);
        - 将代币token，转移到sender地址，数量为amount
        - **将自己的代币直接转给另一个地址**


##### 题目1
编写一个 TokenBank 合约，可以将自己的 Token 存入到 TokenBank， 和从 TokenBank 取出。TokenBank 有两个方法：
- deposit() : 需要记录每个地址的存入数量；
- withdraw（）: 用户可以提取自己的之前存入的 token。

MyToken：
- 这个例子中直接继承自ERC20的token，所有功能都含有了，我们使用的时候直接给出代币基础信息即可

TokenBank：
- owner部署token之后将token给其他一些地址发送一些
- 其他地址存款之前，需要将token先授权给当前合约这样才可以存入token
- 存款的时候使用就是 transferFrom 函数
- 取款的时候使用的是 transfer 函数

解析：见s01.sol

