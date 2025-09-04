

### 基础知识


##### 题目#1：使用 Viem 索引链上ERC20 转账数据并展示
- 后端索引出之前自己发行的 ERC20 Token 转账, 并记录到数据库中，并提供一个 Restful 接口来获取某一个地址的转账记录。
- 前端在用户登录后， 从后端查询出该用户地址的转账记录， 并展示。（前端就算了，没时间做）

**解答**
- 我的sepolia上的代币是：0x1a1Dd7994A1bA16BD2a58cd076EbeA69266587D6
- 编写监听脚本（监听内容直接加入数据库）
    - mkdir viem_monitor
    - cd viem_monitor
    - npm init -y
    - 安装依赖：npm install viem
    - npm install express sqlite3
    - 用 TypeScript，再加：
        - npm install -D typescript ts-node @types/node
        - npx tsc --init
    - npm install -D @types/express
    - mkdir src && touch src/monitor_test.ts
        - 写入内容
    - 进入src运行：npx ts-node monitor_test.ts
        - 然后就可以看到输出
- 运行：进入src运行：npx ts-node monitor_test.ts
- 浏览器查询转账记录：http://localhost:3000/api/transfers/0xFeb5DDA8bbd9746B0b59b0b84964AF37E9172A8C


