
##### 题目1 & 题目2
将下方合约部署到 https://sepolia.etherscan.io/ ，要求如下：
- 要求使用你在 Decert.met 登录的钱包来部署合约
- 要求贴出编写 forge script 的脚本合约
- 并给出部署后的合约链接地址
- 将合约在 https://sepolia.etherscan.io/ 中开源，要求给出对应的合约链接。（题目2合并在这里）
    ```Solidity
    // SPDX-License-Identifier: MIT
    pragma solidity 0.8.25;

    import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

    contract MyToken is ERC20 { 
        constructor(string name_, string symbol_) ERC20(name_, symbol_) {
            _mint(msg.sender, 1e10*1e18);
        } 
    }
    ```

解题：
- 创建项目：
    - mkdir c01 
    - cd c01
    - forge init --no-git
    - forge build
    - forge test
- 安装库：
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
- 部署：
```bash
forge script script/token.s.sol:MyTokenScript \
  --rpc-url $ROPSTEN_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_KEY \
  -vvvv
```

- 结果：https://sepolia.etherscan.io/address/0x81560632846443e245433c4cd737bfc49b0d5470


