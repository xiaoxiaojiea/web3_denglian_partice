
### 基础知识

NFT特殊信息
- 非同质化代币(NFT)：每个tokenId唯一，不可分割
- 每个NFT拥有一个URL：是NFT的唯一资源标识符（URI），通常指向一个 JSON 元数据文件，描述了该 NFT 的具体属性（如名称、描述、图片、动画、特性等）。
    - 前端/市场依赖它显示 NFT：OpenSea、LooksRare、Magic Eden 等 NFT 交易平台会调用 tokenURI() 获取元数据，并渲染 NFT 的图片和信息。
    - 符合 ERC721 元数据标准 的 JSON 文件，结构如下：
        ```json
        {
        "name": "NFT Name #123",
        "description": "This is a description of my NFT.",
        "image": "https://example.com/nft-image.png",
        "external_url": "https://example.com/nft-page",
        "attributes": 
            [
                {
                    "trait_type": "Rarity",
                    "value": "Legendary"
                },
                {
                    "trait_type": "Background",
                    "value": "Blue"
                }
            ]
        }
        ```
        - name：NFT 名称（通常包含编号，如 "CryptoPunk #1234"）
        - description：NFT 描述
        - image：图片 URL（PNG、GIF、MP4 等）
        - external_url：可选，跳转链接（如官网）
        - attributes：特性列表（用于稀有度计算）
    - 常见 tokenURI 模式：
        - 中心化服务器（HTTP/HTTPS）
            - _baseURI = "https://api.mynft.com/token/";
            - 优点：易于更新
            - 缺点：依赖服务器，中心化风险
        -  IPFS（去中心化存储）
            - _baseURI = "ipfs://QmXo9.../";
            - 优点：永久存储，抗审查
            - 缺点：更新较麻烦
        -  On-Chain（完全链上存储）
            - 使用 Base64 编码 的方式将 JSON 和图片数据直接嵌入智能合约，而不依赖外部服务器或 IPFS。
            - 优点：100% 链上，无需外部依赖
            - 缺点：Gas 费高，适合简单 SVG NFT

**tips**：NFT其实也是一个与coin相同的智能合约，只不过NFT定义了唯一ID给每个NFT，相对应的还有一些NFT独特特性而已；


##### 题目1 编写 ERC721 NFT 合约
ERC721 标准代表了非同质化代币（NFT），它为独一无二的资产提供链上表示。从数字艺术品到虚拟产权，NFT的概念正迅速被世界认可。了解并能够实现 ERC721 标准对区块链开发者至关重要。通过这个挑战，你不仅可以熟悉 Solidity 编程，而且可以了解 ERC721 合约的工作原理。

目标：你的任务是创建一个遵循 ERC721 标准的智能合约，该合约能够用于在以太坊区块链上铸造与交易 NFT。

相关资源
为了帮助完成这项挑战，以下资源可能会有用：
• EIP-721标准
• OpenZeppelin ERC721智能合约库

注意
在编写合约时，需要遵循 ERC721 标准，此外也需要考虑到安全性，确保转账和授权功能在任何时候都能正常运行无误。
代码模板中已包含基础框架，只需要在标记为 /**code*/ 的地方编写你的代码。不要去修改已有内容！
提交前需确保通过所有相关的测试用例

解析：见代码s01.sol
- 代码里边有两个合约：1）BaseERC721：这个是自己实现的NFT合约的基本功能（没有继承开源接口）；2）BaseERC721Receiver：NFT转账的时候一方面可以向地址中转，另一方面可以向合约中转，但是被转的合约必须要有onERC721Received方法，防止被转入的合约无法再转出NFT导致NFT被锁死，BaseERC721Receiver就是演示了合约如何定义onERC721Received方法，并且在测试合约BaseERC721的时候可以尝试向一个没有onERC721Received方法的合约（BaseNoneReceiver）转，以及向BaseERC721Receiver合约（BaseERC721Receiver）转，看看效果；
- 一个ID的NFT智能有一个，所以里边有一个_exists方法判断NFT是否被mint过了
- transferFrom，_transfer其实跟普通的coin操作相同，智能合约内部直接修改拥有者就可以了；


代码使用：
- 部署：
    - “TestNFT”, “TNFT”, “https://example.com/token/”  然后点击 deploy
- 关键测试点
    - 基本功能测试：
        - 合约名称和符号是否正确
        - 是否支持正确的接口
    - 铸造功能测试：
        - 能否正确铸造NFT
        - 余额是否正确更新
        - 防止铸造到零地址
        - 防止重复铸造
    - 转账功能测试
        - 所有者能否转
        - 被授权地址能否转账
        - 未授权地址不能转
        - 转账后授权是否被清除
    - 授权功能测试：
        - 单个授权是否有效
        - 批量授权是否有效
        - 授权状态查询是否正确
    - 安全转账测试：
        - 能否转账到普通地址
        - 能否转账到合规合约
        - 不能转账到不合规合约
    - 元数据测试：
        - TokenURI是否正确生成
        - 不存在的TokenURI查询是否失败



