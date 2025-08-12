
 ### NFT智能合约相关知识

NFT智能和与与IPFS之间的关系
- NFT智能合约（如ERC721）的职责：
    - 铸造NFT，管理NFT的唯一标识（tokenId）
    - 记录NFT的拥有者和转移历史
    - 提供一个查询接口tokenURI(tokenId)，告诉外界这个NFT对应的元数据在哪里
- IPFS的职责：IPFS是去中心化的文件存储系统，用来存储：
    - NFT的元数据JSON文件（包含名称、描述、图片链接、属性等）
    - NFT的实际资产文件，比如图片、音频、视频等
- 它们是如何配合的
    - NFT智能合约只存储一个字符串URI（一般是tokenURI），这个URI通常是IPFS的CID地址，比如：ipfs://QmXxxx...
    - 这个URI指向存储在IPFS上的JSON元数据文件，文件格式遵循ERC721标准（含name、description、image等字段）
    - 这个JSON文件里面的image字段又是指向IPFS上的具体媒体文件CID
- 为什么要用IPFS
    - 区块链上直接存储大文件成本极高且不现实
    - IPFS能去中心化存储大文件，保证内容不可篡改且持久
    - 通过IPFS的CID（内容哈希）能保证数据的完整性和唯一性


#### 题目1：用 ERC721 标准（可复用 OpenZepplin 库）发行一个自己 NFT 合约，并用图片铸造几个 NFT ， 请把图片和 Meta Json数据上传到去中心的存储服务中，请贴出在 OpenSea 的 NFT 链接。
> OpenSea测试网已经停止运行了，所以我使用了替代方案：https://testnet.rarible.com/
> 去中心的存储服务我选择使用的是：https://console.filebase.com/

核心思想：见“NFT智能和与与IPFS之间的关系”

代码解析见：s01.sol
- 到网站https://console.filebase.com/上传image与meta_data.json
    - 其中meta_data.json中的image记得修改为上传image的CID
    - 上传的meta_data.json见 s01_sources/nft_matedate.json 文件
    - 上传的ipfs文件可以浏览器查看：https://ipfs.io/ipfs/QmNrKkmZkJ3ryt5Ty5z6AxpvXyTC9TAovtFaqqMo6pvZRy
- 然后将nft_matedate.json文件的CID设置到s01.sol文件的metaDataURI_边量中
- 部署（“DengLianNFTDemo”，“DLNFT”）和与，为某个地址mint一个nft即可
    - 合约地址：0x0cf1dC8A58A6413c49746D5ff1A08c64b29D54CE
    - rarible上查看的NFT：https://testnet.rarible.com/token/0x0cf1dc8a58a6413c49746d5ff1a08c64b29d54ce:0
        - 注意：rarible上显示有问题，显示不出来图片与信息


#### 题目2：NFTMarket
编写一个简单的 NFTMarket 合约，使用自己发行的ERC20 扩展 Token 来买卖 NFT， NFTMarket 的函数有：
- list() : 实现上架功能，NFT持有者可以设定一个价格（需要多少个Token购买该NFT）并上架NFT到NFTMarket，上架之后，其他人才可以购买。
- buyNFT() : 普通的购买NFT功能，用户转入所定价的token数量，获得对应的NFT。
实现ERC20扩展Token所要求的接收者方法tokensReceived，在tokensReceived中实现NFT购买功能(注意扩展的转账需要添加一个额外数据参数)。

项目分析：
- 主要思想：
    - 部署了 MyNFT、MyToken 和 NFTMarket 三个合约，并且 NFTMarket 构造传入 MyToken 地址
    - 卖家将自己的所有NFT授权给市场
    - 卖家调用 list 将自己的所有NFT转移到NFTMarket中，用于展示售卖；
    - 买家有两种买法：
        - 普通买：先 approve(marketAddr, price)，再 buyNFT(nftAddr, tokenId)
            - 内部会将token转移到售卖人的地址，将nft转移到调用者的地址；
        - 回调买：直接调用token合约的函数transferAndCall，内部会调用NFTMarket合约的tokensReceived函数来购买NFT；

- 三个合约各自的核心工作
    - MyNFT (ERC721)：只管NFT的发行和转移。
        - mint()铸造：给地址to铸造一个nft;
        - transferFrom()转移：替代转账功能将tokenId从地址from转移到地址to;
    - MyToken (ERC20)：提供购买用的代币，并支持“带数据转账”，为回调购买模式提供可能。
        - transfer()：sender向地址to转一定数量的coin
        - transferAndCall()（扩展功能）：该函数会调用Market合约的购买NFT功能，实现回调的方式购买NFT
    - NFTMarket：作为交易撮合中心，管理上架与成交，能兼容普通购买和回调购买两种模式。
        - list() 上架：卖方将NFT转移到market合约，等同于挂到了市场上了；
        - buyNFT() 普通购买：在market购买
        - tokensReceived() 回调购买：直接在token中购买

使用流程：
- 使用主钱包（0x8959404600A476Dd57F2CA080fA4A69Fcee73797）部署三个合约：
    - MyNFT： 0x0cf1dC8A58A6413c49746D5ff1A08c64b29D54CE
        - DengLianNFTDemo
        - DLNFT
    - MyToken： 0x39ce7386831f805De2285054EFE00FB8cA0C08F3
        - NFTToken
        - NT
        - 6000000000000000000000 其实就是6000个总量
    - NFTMarket： 0xd8058be6804E42b44C0CEe10aFfb214D22d7763A
        - 0x39ce7386831f805De2285054EFE00FB8cA0C08F3
- MyNFT：给主钱包多mint几个NFT，加入mint了ID为3，4的两个NFT
    - https://testnet.rarible.com/user/0x8959404600A476Dd57F2CA080fA4A69Fcee73797/owned 可以查看钱包下的所有该nft（我这里的主钱包是0x8959404600A476Dd57F2CA080fA4A69Fcee73797）
    - 主钱包将自己的所有NFT授权给NFTMarket
- MyToken：主钱包给副钱包发送一些Token
    - 钱包 0xfeb5dda8bbd9746b0b59b0b84964af37e9172a8c 转 1000000000000000000000 其实就是1000个
- NFTMarket：主钱包上架ID为3，4的NFT（要提前授权），并且价格均设置为 10000000000000000000 其实就是10个
- 切换到副钱包：
    - 直接购买：
        - 副钱包将自己的Token授权给NFTMarket
        - 然后调用NFTMarket的buyNFT就可以购买了
    - 回调购买：
        - 副钱包调用MyToken的transferAndCall购买
        - 其中transferAndCall需要的calldata可以使用encodeNFTData进行编码
- 然后通过以下链接就可以看到刚才购买的NFT了
    - https://testnet.rarible.com/user/0xfeb5dda8bbd9746b0b59b0b84964af37e9172a8c/owned

