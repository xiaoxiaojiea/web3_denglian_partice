
### 基础知识

**EIP-712**
- EIP-712 定义了一种 结构化数据签名标准，它的目标是解决传统 eth_sign / personal_sign 的两个问题：
    - 人类可读性差：普通签名显示一堆 hex，不知道自己在签啥。
    - 防重放攻击：同样的消息可能被拿去别的链、别的场景再次使用。
- 所以，EIP-712 定义了一个 Typed Structured Data 的签名格式，让用户看到的签名更清晰、可读，并且签名数据里包含 domain separator（链 ID、合约地址、用途），防止跨链、跨合约的重放。
- EIP-712 的核心结构，签名内容主要分两部分：
    - Domain Separator：定义签名属于哪个合约/链
        ```Solidity
        struct EIP712Domain {
            string  name;
            string  version;
            uint256 chainId;
            address verifyingContract;
        }
        ```
    - Message（业务相关数据）：比如 Permit 授权参数
        ```Solidity
        struct Permit {
            address owner;
            address spender;
            uint256 value;
            uint256 nonce;
            uint256 deadline;
        }
        ```
    - 最终签名的数据是：
        ```Solidity
        keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(encode(Permit))
            )
        )
        ```

**ERC20 Permit (EIP-2612) 与离线授权**
- 传统 ERC20 授权 需要：
    - 用户先 approve(spender, amount)（on-chain 交易，需 gas）
    - spender 再调用 transferFrom
    - 问题：要两次交易，用户授权很麻烦。
- Permit 模式（离线签名）:
    - 用户用钱包对 Permit 结构签名（EIP-712），不花 gas
    - 签名结果 (v,r,s) 交给 spender
    - spender 调用合约的 permit(...)，合约验证签名后，直接更新 allowance
    - 这样 只需要一次 on-chain 调用，就完成了授权，节省了 gas。

**基于 EIP-712 签名的白名单设计**
- 白名单场景下（比如 NFT 预售 / 私募），常见的做法是：
    - 项目方离线生成签名（用 EIP-712），内容包括：
    ```Solidity
    struct Whitelist {
        address user;
        uint256 maxMint;
        uint256 deadline;
    }
    ```
    - 用户调用合约的 mintWithSig(signature)，传入签名。
    - 合约验证签名是否合法（是否由项目方签发），如果合法 → 允许用户 mint。
    - 这样就避免了把所有白名单地址写进链上（节省存储费），而是用一个签名机制来动态证明「我在白名单里」。

**比较**
| 功能       | 传统做法                   | EIP-712 + Permit / 签名做法    |
| -------- | ---------------------- | -------------------------- |
| Token 授权 | approve → transferFrom | 用户离线签名 → spender 调用 permit |
| 白名单验证    | 链上存白名单数组               | 离线签名验证（更省 gas）             |
| 优势       | 简单，标准                  | 更省 gas，更灵活，可跨 Dapp         |

**用法**
- 一个 MyToken 继承了 ERC20Permit (EIP-2612)后，便支持 permit 离线签名授权，允许用户无需提前 approve，直接通过签名 + permit 来完成授权；
- 一个应用型的合约TokenBank如果想对某个Token做离线签名使用，那么必须内部实现两个Token相关的实例
    - 一个IERC20 public token：代币实例，用于普通的 transferFrom 存款
    - 一个IERC20Permit public permitToken：同一个代币，但用的是 IERC20Permit 接口，用于 离线签名授权（permit） 的存款。
    - TokenBank中离线签名之后，用户只需 离线签名一条 permit 消息，再直接调用 permitDeposit，即可一步完成授权 + 存款。
- 另一个应用型合约NFTMarket，项目放离线签名了可以购买NFT的用户，然后才被签名的用户才可以购买NFT。

**总结**
- **permit 是一种授权机制，允许用户通过签名授权合约执行某些操作，围绕这个思想可以做很多事情。**
- permitDeposit 和 permitBuy 是与 permit 机制相关的特定操作，分别用于存款和购买，但它们不是 permit 的两种用法，而是更具体的操作。


##### 题目#1
理解 EIP712 标准，尝试掌握用离线签名（Permit）的方式来进行 Token 的授权和白名单设计。
- 使用 EIP2612 标准（可基于 Openzepplin 库）编写一个自己名称的 Token 合约。
- 修改 TokenBank 存款合约 ,添加一个函数 permitDeposit 以支持离线签名授权（permit）进行存款, 并在TokenBank前端 加入通过签名存款。
- 修改Token 购买 NFT NTFMarket 合约，添加功能 permitBuy() 实现只有离线授权的白名单地址才可以购买 NFT （用自己的名称发行 NFT，再上架） 。白名单具体实现逻辑为：项目方给白名单地址签名，白名单用户拿到签名信息后，传给 permitBuy() 函数，在permitBuy()中判断时候是经过许可的白名单用户，如果是，才可以进行后续购买，否则 revert 。
要求：
- 有 Token 存款及 NFT 购买成功的测试用例
- 有测试用例运行日志或截图，能够看到 Token 及 NFT 转移。

**项目分析**
- 我直接使用foundry测试来做实验，没有添加前端，主要是验证功能是否正常；

**合约项目编写**
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
- 执行Test：测试内容里边有很多




jie@jie:~/shj_other_ws/学习记录/web3课程02_登链/module-05/d07/c01$ forge test -vvvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 9 tests for test/PermitTest.t.sol:PermitTest
[PASS] test_buy_normal() (gas: 141611)
Traces:
  [182279] PermitTest::test_buy_normal()
    ├─ [0] VM::startPrank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [27439] TestNFT::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, approved: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   └─ ← [Stop] 
    ├─ [83296] NFTMarket::list(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0, 100)
    │   ├─ [37106] TestNFT::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [25296] MyToken::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 100)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, spender: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], value: 100)
    │   └─ ← [Return] true
    ├─ [20320] NFTMarket::buy(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0)
    │   ├─ [9714] MyToken::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, 100)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, value: 100)
    │   │   └─ ← [Return] true
    │   ├─ [4967] TestNFT::transferFrom(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, 0)
    │   │   ├─ emit Transfer(from: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], to: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, tokenId: 0)
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [1005] TestNFT::ownerOf(0) [staticcall]
    │   └─ ← [Return] 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
    └─ ← [Stop] 

[PASS] test_deposit_normal() (gas: 81401)
Traces:
  [101301] PermitTest::test_deposit_normal()
    ├─ [0] VM::startPrank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [25296] MyToken::approve(TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 50)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, spender: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 50)
    │   └─ ← [Return] true
    ├─ [57537] TokenBank::deposit(50)
    │   ├─ [31614] MyToken::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 50)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 50)
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [780] TokenBank::balances(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf) [staticcall]
    │   └─ ← [Return] 50
    └─ ← [Stop] 

[PASS] test_permitBuy_fail_expired() (gas: 143535)
Traces:
  [168235] PermitTest::test_permitBuy_fail_expired()
    ├─ [0] VM::startPrank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [27439] TestNFT::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, approved: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   └─ ← [Stop] 
    ├─ [83296] NFTMarket::list(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0, 100)
    │   ├─ [37106] TestNFT::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [25296] MyToken::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 100)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, spender: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], value: 100)
    │   └─ ← [Return] true
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::sign("<pk>", 0xf9f23f7ecc7daf1c7fe8fa5868cae3b5780a0c8ad6c1c9a6044b2cac8e64da27) [staticcall]
    │   └─ ← [Return] 28, 0x8e07db899f44c44209ba03321a9ce9ff2e8859ad09483d5715bce041c301bf11, 0x65704ed4eb314f3cefca1e8c094d5958492fcb78cd0d2cd90e1228a6a8847550
    ├─ [0] VM::prank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3:  expired)
    │   └─ ← [Return] 
    ├─ [1643] NFTMarket::permitBuy(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0, 0, 28, 0x8e07db899f44c44209ba03321a9ce9ff2e8859ad09483d5715bce041c301bf11, 0x65704ed4eb314f3cefca1e8c094d5958492fcb78cd0d2cd90e1228a6a8847550)
    │   └─ ← [Revert] revert: expired
    └─ ← [Stop] 

[PASS] test_permitBuy_fail_notWhitelisted() (gas: 150908)
Traces:
  [175608] PermitTest::test_permitBuy_fail_notWhitelisted()
    ├─ [0] VM::startPrank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [27439] TestNFT::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, approved: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   └─ ← [Stop] 
    ├─ [83296] NFTMarket::list(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0, 100)
    │   ├─ [37106] TestNFT::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [25296] MyToken::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 100)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, spender: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], value: 100)
    │   └─ ← [Return] true
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::sign("<pk>", 0x803481671caa7532534c9473a86c9ebe310d8741104924b50330081edb3c88fe) [staticcall]
    │   └─ ← [Return] 27, 0x7199a7303b202ac5f9f21ea4ed248b616dc221612f44085549218e628faf4c05, 0x328ef4e0280c34ad91a13ab7f7e03fe628e5cf1471b7e16bdc278656a9923a49
    ├─ [0] VM::prank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [0] VM::expectRevert(custom error 0xf28dceb3:  not whitelisted)
    │   └─ ← [Return] 
    ├─ [9016] NFTMarket::permitBuy(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0, 3601, 27, 0x7199a7303b202ac5f9f21ea4ed248b616dc221612f44085549218e628faf4c05, 0x328ef4e0280c34ad91a13ab7f7e03fe628e5cf1471b7e16bdc278656a9923a49)
    │   ├─ [3000] PRECOMPILES::ecrecover(0x803481671caa7532534c9473a86c9ebe310d8741104924b50330081edb3c88fe, 27, 51382833382764206715014083474870611209385539840903783652777175984819206573061, 22868224781716033163476469476324970391503466018533554087177342040712831711817) [staticcall]
    │   │   └─ ← [Return] 0x0000000000000000000000006813eb9362372eef6200f3b1dbc3f819671cba69
    │   └─ ← [Revert] revert: not whitelisted
    └─ ← [Stop] 

[PASS] test_permitBuy_success() (gas: 153094)
Traces:
  [196633] PermitTest::test_permitBuy_success()
    ├─ [0] VM::startPrank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [27439] TestNFT::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, approved: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   └─ ← [Stop] 
    ├─ [83296] NFTMarket::list(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0, 100)
    │   ├─ [37106] TestNFT::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], tokenId: 0)
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [25296] MyToken::approve(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 100)
    │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, spender: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], value: 100)
    │   └─ ← [Return] true
    ├─ [0] VM::stopPrank()
    │   └─ ← [Return] 
    ├─ [0] VM::sign("<pk>", 0x803481671caa7532534c9473a86c9ebe310d8741104924b50330081edb3c88fe) [staticcall]
    │   └─ ← [Return] 28, 0xcbd9d006117d4312568a0b8b74b35f9ff4bc6c7a2038e728bfe9cfdb83a1067b, 0x125950374976a5b8471d66aecf4cf02e927379a94d095dcdc1f832af03f399a1
    ├─ [0] VM::prank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [28416] NFTMarket::permitBuy(TestNFT: [0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9], 0, 3601, 28, 0xcbd9d006117d4312568a0b8b74b35f9ff4bc6c7a2038e728bfe9cfdb83a1067b, 0x125950374976a5b8471d66aecf4cf02e927379a94d095dcdc1f832af03f399a1)
    │   ├─ [3000] PRECOMPILES::ecrecover(0x803481671caa7532534c9473a86c9ebe310d8741104924b50330081edb3c88fe, 28, 92204349802301637435216497683156323976176873810597218487084984086896171878011, 8299434293505487112194335100687597714038315671296516868550696251161314564513) [staticcall]
    │   │   └─ ← [Return] 0x0000000000000000000000002b5ad5c4795c026514f8317c7a215e218dccd6cf
    │   ├─ [9714] MyToken::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, 100)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, value: 100)
    │   │   └─ ← [Return] true
    │   ├─ [4967] TestNFT::transferFrom(NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, 0)
    │   │   ├─ emit Transfer(from: NFTMarket: [0xF62849F9A0B5Bf2913b396098F7c7019b51A820a], to: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, tokenId: 0)
    │   │   └─ ← [Stop] 
    │   └─ ← [Stop] 
    ├─ [1005] TestNFT::ownerOf(0) [staticcall]
    │   └─ ← [Return] 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf
    └─ ← [Stop] 

[PASS] test_permitDeposit_fail_expired() (gas: 32381)
Traces:
  [32381] PermitTest::test_permitDeposit_fail_expired()
    ├─ [2916] MyToken::nonces(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf) [staticcall]
    │   └─ ← [Return] 0
    ├─ [555] MyToken::DOMAIN_SEPARATOR() [staticcall]
    │   └─ ← [Return] 0x47133852c428439caec9902de2cb330e249f30b0e04964de018a0a7ba0b64781
    ├─ [0] VM::sign("<pk>", 0xd29f9e59904f5e2a6adab9a1cc88a18db0e35c8e02ffddfee28fe3ead01d9be2) [staticcall]
    │   └─ ← [Return] 28, 0x791af0ff159433974a0bd4cb3c18e684a5ae0148efccdb62a171564977f72c9f, 0x620cdfed122ae14ed80d22810b3e4bb874e899aa9fc16a7915a6055e147da9cf
    ├─ [0] VM::prank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [0] VM::expectRevert(custom error 0xf4844814)
    │   └─ ← [Return] 
    ├─ [6245] TokenBank::permitDeposit(100000000000000000000 [1e20], 0, 28, 0x791af0ff159433974a0bd4cb3c18e684a5ae0148efccdb62a171564977f72c9f, 0x620cdfed122ae14ed80d22810b3e4bb874e899aa9fc16a7915a6055e147da9cf)
    │   ├─ [1787] MyToken::permit(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100000000000000000000 [1e20], 0, 28, 0x791af0ff159433974a0bd4cb3c18e684a5ae0148efccdb62a171564977f72c9f, 0x620cdfed122ae14ed80d22810b3e4bb874e899aa9fc16a7915a6055e147da9cf)
    │   │   └─ ← [Revert] ERC2612ExpiredSignature(0)
    │   └─ ← [Revert] ERC2612ExpiredSignature(0)
    └─ ← [Stop] 

[PASS] test_permitDeposit_fail_invalidSig() (gas: 58127)
Traces:
  [58127] PermitTest::test_permitDeposit_fail_invalidSig()
    ├─ [2916] MyToken::nonces(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf) [staticcall]
    │   └─ ← [Return] 0
    ├─ [555] MyToken::DOMAIN_SEPARATOR() [staticcall]
    │   └─ ← [Return] 0x47133852c428439caec9902de2cb330e249f30b0e04964de018a0a7ba0b64781
    ├─ [0] VM::sign("<pk>", 0xb1b6b875b903e99a46859733b369a53a13af1f5bb3f218ef7073dcab464cdb63) [staticcall]
    │   └─ ← [Return] 28, 0x5e2592a66357efc2935d0fdefd990ae69f954c37ad40b5f8541f86f6b7c8cf20, 0x44f6d53ed541f8effd0da785c6575e3169d98bc305d1b8f4870a7f046f778727
    ├─ [0] VM::prank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [0] VM::expectRevert(custom error 0xf4844814)
    │   └─ ← [Return] 
    ├─ [31992] TokenBank::permitDeposit(100000000000000000000 [1e20], 3601, 28, 0x5e2592a66357efc2935d0fdefd990ae69f954c37ad40b5f8541f86f6b7c8cf20, 0x44f6d53ed541f8effd0da785c6575e3169d98bc305d1b8f4870a7f046f778727)
    │   ├─ [27531] MyToken::permit(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100000000000000000000 [1e20], 3601, 28, 0x5e2592a66357efc2935d0fdefd990ae69f954c37ad40b5f8541f86f6b7c8cf20, 0x44f6d53ed541f8effd0da785c6575e3169d98bc305d1b8f4870a7f046f778727)
    │   │   ├─ [3000] PRECOMPILES::ecrecover(0xb1b6b875b903e99a46859733b369a53a13af1f5bb3f218ef7073dcab464cdb63, 28, 42583793249003710775478779813203446115029578484625083568502305358722567294752, 31193389847544814309416216081997796101176262896915180922498369680559387936551) [staticcall]
    │   │   │   └─ ← [Return] 0x0000000000000000000000006813eb9362372eef6200f3b1dbc3f819671cba69
    │   │   └─ ← [Revert] ERC2612InvalidSigner(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69, 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Revert] ERC2612InvalidSigner(0x6813Eb9362372EEF6200f3b1dbC3f819671cBA69, 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    └─ ← [Stop] 

[PASS] test_permitDeposit_success() (gas: 120829)
Traces:
  [140729] PermitTest::test_permitDeposit_success()
    ├─ [2916] MyToken::nonces(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf) [staticcall]
    │   └─ ← [Return] 0
    ├─ [555] MyToken::DOMAIN_SEPARATOR() [staticcall]
    │   └─ ← [Return] 0x47133852c428439caec9902de2cb330e249f30b0e04964de018a0a7ba0b64781
    ├─ [0] VM::sign("<pk>", 0xb1b6b875b903e99a46859733b369a53a13af1f5bb3f218ef7073dcab464cdb63) [staticcall]
    │   └─ ← [Return] 28, 0x7119d0795d7453726ba4256e0e2298e64cea2b5c21c933e8fbca2f57f0caf6b2, 0x7c3697d1f8b9858b37cd37469af196d484f37d9fd5c2765b0c8f838213d5727e
    ├─ [0] VM::prank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [113155] TokenBank::permitDeposit(100000000000000000000 [1e20], 3601, 28, 0x7119d0795d7453726ba4256e0e2298e64cea2b5c21c933e8fbca2f57f0caf6b2, 0x7c3697d1f8b9858b37cd37469af196d484f37d9fd5c2765b0c8f838213d5727e)
    │   ├─ [51589] MyToken::permit(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100000000000000000000 [1e20], 3601, 28, 0x7119d0795d7453726ba4256e0e2298e64cea2b5c21c933e8fbca2f57f0caf6b2, 0x7c3697d1f8b9858b37cd37469af196d484f37d9fd5c2765b0c8f838213d5727e)
    │   │   ├─ [3000] PRECOMPILES::ecrecover(0xb1b6b875b903e99a46859733b369a53a13af1f5bb3f218ef7073dcab464cdb63, 28, 51156961901764137508345173240786910087014086953176917353101886136868523407026, 56183250790344051237928881263365358254693565113949966572740521327764578857598) [staticcall]
    │   │   │   └─ ← [Return] 0x0000000000000000000000007e5f4552091a69125d5dfcb7b8c2659029395bdf
    │   │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, spender: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 100000000000000000000 [1e20])
    │   │   └─ ← [Stop] 
    │   ├─ [31614] MyToken::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 100000000000000000000 [1e20])
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 100000000000000000000 [1e20])
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [780] TokenBank::balances(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf) [staticcall]
    │   └─ ← [Return] 100000000000000000000 [1e20]
    └─ ← [Stop] 

[PASS] test_permitDeposit_zeroAmount() (gas: 78293)
Traces:
  [78293] PermitTest::test_permitDeposit_zeroAmount()
    ├─ [2916] MyToken::nonces(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf) [staticcall]
    │   └─ ← [Return] 0
    ├─ [555] MyToken::DOMAIN_SEPARATOR() [staticcall]
    │   └─ ← [Return] 0x47133852c428439caec9902de2cb330e249f30b0e04964de018a0a7ba0b64781
    ├─ [0] VM::sign("<pk>", 0xaa4d6984cdcde2ddd63a308c1ddea7d2b1f70cfb5d26d8a273a39c433250e318) [staticcall]
    │   └─ ← [Return] 28, 0xefb4e8e413815b8218242807b37f528c2c93e641c9d43b2de699668313acc546, 0x35df3966c6ff19ebc1c3e94aebd208db3d76169bcd97251b855f97367ba3c6a8
    ├─ [0] VM::prank(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf)
    │   └─ ← [Return] 
    ├─ [50655] TokenBank::permitDeposit(0, 3601, 28, 0xefb4e8e413815b8218242807b37f528c2c93e641c9d43b2de699668313acc546, 0x35df3966c6ff19ebc1c3e94aebd208db3d76169bcd97251b855f97367ba3c6a8)
    │   ├─ [31689] MyToken::permit(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0, 3601, 28, 0xefb4e8e413815b8218242807b37f528c2c93e641c9d43b2de699668313acc546, 0x35df3966c6ff19ebc1c3e94aebd208db3d76169bcd97251b855f97367ba3c6a8)
    │   │   ├─ [3000] PRECOMPILES::ecrecover(0xaa4d6984cdcde2ddd63a308c1ddea7d2b1f70cfb5d26d8a273a39c433250e318, 28, 108422410637135219633347415873222929849775751704326966117559565923131029505350, 24366984040771801720009073616612543985840563043562682218135274091612914042536) [staticcall]
    │   │   │   └─ ← [Return] 0x0000000000000000000000007e5f4552091a69125d5dfcb7b8c2659029395bdf
    │   │   ├─ emit Approval(owner: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, spender: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 0)
    │   │   └─ ← [Stop] 
    │   ├─ [8914] MyToken::transferFrom(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 0)
    │   │   ├─ emit Transfer(from: 0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf, to: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 0)
    │   │   └─ ← [Return] true
    │   └─ ← [Stop] 
    ├─ [780] TokenBank::balances(0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf) [staticcall]
    │   └─ ← [Return] 0
    └─ ← [Stop] 

Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 4.26ms (8.44ms CPU time)

Ran 1 test suite in 1.03s (4.26ms CPU time): 9 tests passed, 0 failed, 0 skipped (9 total tests)



