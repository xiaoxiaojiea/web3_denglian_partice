

### 基础知识

**delegatecall VS. Clones库**
- delegatecall：Proxy + delegatecall 可用于合约升级；
    - 之前我们学习的时候知道可以使用delegatecall在代理合约中回调目标合约，以此实现合约升级的功能，delegatecall特性如下：
        - delegatecall 是 EVM 的一个低级指令，用来实现 代码逻辑共享；
        - A 合约用 delegatecall 调用 B 合约 → 执行 B 的代码，但 上下文 (storage, msg.sender, msg.value) 还是 A 的。
        - 但是**在部署A合约的时候，相当于把B合约全部拷贝到了A合约中进行部署**，这样的合约可以用于合约升级，但是部署成本很高（因为用到了全部代码）；
- Clones：永远 delegatecall 到一个指定的 implementation,implementation 地址不可变,不可升级;
    - 最小代理合约字节码，代码只干一件事：delegatecall 到指定的实现合约 (implementation)，不将实现合约拷贝到代理合约中;
    - 部署时存储一段极小的汇编（~45字节）。
        ```
            0x3d602d80600a3d3981f3       // 部署时的 init code
            0x363d3d373d3d3d363d73<impl_address>5af43d82803e903d91602b57fd5bf3
        ```
        - 整个代理合约字节码不到 100字节。所以 gas 成本极低，部署成本也极低。
- 区别：
    - Proxy+delegatecall
        - 部署每个 Proxy = 部署完整合约字节码 (可能几千字节)，成本高。
        - 灵活性强，可以实现可升级逻辑、存储变量。
    - Clone
        - 部署的是 一段固定的最小汇编字节码，字节码非常短（几十字节），成本极低（gas 节省 90% 以上）。
        - clone 逻辑非常固定，永远 delegatecall 到一个指定的 implementation，不可升级（因为 implementation 地址不可变）。
- 针对当前题目应该选用Clone：因为Meme Token 工厂，要部署几百上千个代币，该代币合约是固定的，后续无需再升级代币合约；


**最小代理合约（Minimal Proxy / EIP-1167） 的原理**
- 在以太坊上部署一个完整的 ERC20 合约需要消耗不少 Gas（比如 50k–100k 以上）。如果你要发射很多 Meme Token，每个都单独部署，会非常贵。
- 解决方案 👉 使用 最小代理合约（Minimal Proxy），也叫 Clone 合约，它本质是一个小的合约，里面的逻辑只有：（这样每个 Meme Token 只需一个极小的“外壳”，Gas 成本非常低。）
    - 把所有调用转发（delegatecall）到一个已存在的逻辑合约（Implementation 合约）；
    - 自己不存储逻辑，只存储数据（存储空间是独立的）。

**最小代理合约（Minimal Proxy / EIP-1167） 的使用**
- 逻辑合约 (Implementation)
    - 包含完整的 ERC20 代码（比如 MemeERC20）
    - 不直接使用，只作为模板。
- 最小代理合约 (Proxy)
    - 内部只保存一段很短的 EVM 字节码，大概 45 字节左右。
    - 所有函数调用都会 delegatecall 到逻辑合约。
    - 存储独立，可以初始化不同的 symbol / totalSupply / perMint / price。
- 工厂合约 (Factory)
    - 负责部署这些最小代理。
    - 使用 create 或 create2 指令来部署 proxy。
    - 常见实现方式：Clones 库（OpenZeppelin 提供）。

**合约部署的方式 create，create2，create3**
- create：最原始的合约部署指令（EVM Opcode: 0xf0）
    - 地址计算公式：address = keccak256(rlp([sender, nonce]))[12:]
        - sender = 部署交易发起方（外部账户或合约）。
        - nonce = 该账户的交易次数 / 合约创建次数。
    - 特点：
        - 地址依赖部署者和当时的 nonce。
        - 无法提前确定（除非预先知道 nonce）。
        - 每次部署相同代码 → 地址不同。
    - 常用场景：
        - 普通合约部署。
        - 不要求地址可预测。

- create2: 由 EIP-1014 (2018) 引入，核心是让合约地址 可预测。
    - 地址计算公式：address = keccak256(0xff ++ sender ++ salt ++ keccak256(init_code))[12:]
        - 0xff = 固定常量，避免冲突。
        - sender = 部署者地址。
        - salt = 部署时传入的盐值（任意 32 字节）。
        - init_code = 部署时的合约字节码。
    - 特点：
        - 地址与 salt 强绑定，可提前计算。
        - 只要 salt 和 init_code 一样 → 地址永远相同。
        - 如果合约还没部署，地址就是“预留地址”（counterfactual contract）
    - 常用场景：
        - 可预测的合约部署（DeFi 工厂、钱包工厂、Meme 发射平台）。
        - 抢跑/预部署（比如 Uniswap v3 Pool 地址）。

- create3: 改进 CREATE2，让地址在合约升级 / 字节码变化时也保持稳定。不是官方EVM指令，社区提出的（0xSequence的库）.
    - 问题（CREATE2 的不足）：地址计算依赖 init_code，所以逻辑合约升级时地址会变 → 不利于长期绑定。
    - CREATE3 的改进：
        - 使用两步部署：先用 CREATE2 部署一个固定的中继合约，再由这个中继合约用 CREATE 部署真正的目标合约。
        - 地址只与 salt 和部署者相关，不依赖目标 init_code。
    - 特点：
        - 合约逻辑可以变化（代码变了，地址不变）。
        - 更适合 “永久地址 + 可升级逻辑” 的场景。
    - 常用场景：
        - 钱包工厂（用户地址固定，内部逻辑可升级）。
        - 长期绑定的 Meme 发射器 / NFT 合约地址。
    - **原理详解**：
        - create创建的合约地址依赖：sender + nonce
        - create2创建的合约地址依赖：salt + init_code
        - 于是每次使用CREATE3 模式时，都会经历下边两个步骤：
            - 第一步：用create2部署一个中继合约
                - 这个合约地址只依赖 salt 和 init_code；
                - 只要确保中继合约 (Deployer)代码没有被修改过，init_code 就不会变，该中继合约地址就不会变。
            - 第二步：由这个中继合约，再用普通的create部署目标合约
                - 目标合约只依赖 sender 和 nonce；
                - sender就是中继合约地址，每次中继合约都是新的所以nonce每次都是从1开始
        - create3使用的前提是合约允许被销毁，这样相同地址的中继合约才能被反复部署，但是现在合约不允许被销毁了，所以create3目前智能用来预测与代码无关、与nonce无关的合约地址，而不能永远保证目标合约地址不变。

##### 题目

**用最小代理实现 ERC20 铸币工厂**

假设你（项目方）正在EVM 链上创建一个Meme 发射平台，每一个 MEME 都是一个 ERC20 token ，你需要编写一个通过最⼩代理方式来创建 Meme的⼯⼚合约，以减少 Meme 发行者的 Gas 成本，编写的⼯⼚合约包含两个方法：
- deployMeme(string symbol, uint totalSupply, uint perMint, uint price)
    - Meme发行者调⽤该⽅法创建ERC20 合约（实例）, 参数描述如下： 
        - symbol 表示新创建代币的代号（ ERC20 代币名字可以使用固定的）
        - totalSupply 表示总发行量
        - perMint 表示一次铸造 Meme 的数量（为了公平的铸造，而不是一次性所有的 Meme 都铸造完）
        - price 表示每个 Meme 铸造时需要的支付的费用（wei 计价）。每次铸造费用分为两部分，一部分（1%）给到项目方（你），一部分给到 Meme 的发行者（即调用该方法的用户）。
- mintMeme(address tokenAddr) payable
    - 购买 Meme 的用户每次调用该函数时，会发行 deployInscription 确定的 perMint 数量的 token，并收取相应的费用。

要求：
- 包含测试用例（需要有完整的 forge 工程）
    - 费用按比例正确分配到 Meme 发行者账号及项目方账号。
    - 每次发行的数量正确，且不会超过 totalSupply.

**代码编写：EIP-1167最小代理合约**
- 项目分析：
    - 需求：
        - 我作为项目方，想搭建一个 MemeToken 平台；
        - 用户（Meme 发射者）来这里可以 一键创建自己的 ERC20 代币（MemeToken）；
        - 投资者（买币用户）可以来工厂调用 mintInscription，花 ETH 购买代币；
        - 每次购买，项目方收取 1% 手续费，其余的 ETH 给 Meme 的创建者
    - 最小代理的实现思路：
        - 我们可以将 Meme代币的逻辑合约MemeToken 看作是一个类模板（或者结构体），他的功能只是提供了代币模板；
        - MemeFactory是创建一个个Meme代币实例的入口，该合约部署时内部会记录MemeToken模板（存储在implementation中）；
            - 后面所有 MemeToken 实例都是通过 克隆implementation模板 来实例化的（传入新的token标识即可）
            - 同时 MemeFactory也提供了mint MemeToken 实例的功能
        - 因此，部署项目的时候只需要部署MemeFactory，不需要部署MemeToken，因为MemeToken在MemeFactory里面相当于只提供了模板
    - 需要注意：见 MemeToken1.sol
        - 当前MemeToken合约使用的是ERC20，模板合约的 constructor 只会在 逻辑合约本身 部署时执行一次，clone 出来的 最小代理合约 并不会再次执行 constructor，而是直接通过 delegatecall 调用模板的逻辑。这意味着：ERC20("MemeToken", "MMT") 初始化的 name 和 symbol 永远是 ""（因为constructor没有被执行），并且后面的 initialize 无法覆盖。
        - 所以现在的写法会导致：你 clone 出来的所有 MemeToken，名字都叫 ""，符号是空字符串 ""。
        - 如果你想让每个克隆出来的 Token 有自己的名字和符号，应该用 可初始化的 ERC20 模板，而不是构造函数固定。
            - OpenZeppelin 已经为这种场景准备了 ERC20Upgradeable + initialize 模式（我当前库中没找到到）
    - 改进MemeToken.sol
        - 这里里面修改了meme代币的name与symbol初始化方式，使得每个代币都可以设置不同的name与symbol
    

- 创建项目：
    - mkdir c01 && cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt
    - wget https://github.com/OpenZeppelin/openzeppelin-contracts/archive/refs/heads/master.zip -O oz.zip
        - unzip oz.zip -d lib/
        - mv lib/openzeppelin-contracts-master lib/openzeppelin-contracts
        - rm oz.zip
    - 生成 Remappings: forge remappings > remappings.txt

然后编写代码就好了



















