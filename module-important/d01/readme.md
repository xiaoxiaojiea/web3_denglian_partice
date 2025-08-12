

### transfer与transferFrom关键区别
transfer 和 transferFrom 是 ERC20 代币转账的两种核心方式，关键区别在于谁发起转账以及是否需要预授权（approve）。

核心区别：
- transfer:
    - 调用者是谁: 代币拥有者
    - 代币从哪扣: 调用者账户
    - 是否需要提前 approve: 不需要
    - 常见用途: 直接把自己的代币给别人
- transferFrom:     
    - 调用者是谁: 代币拥有者授权的第三方（spender）
    - 代币从哪扣: 被授权人的账户
    - 是否需要提前 approve: 需要先 approve
    - 常见用途: 代付、代扣、交易市场付款
- **在使用到transferFrom的时候，一定要注意是否经过了授权**

**重点注意事项**
- 见例子：s01.sol，s02.sol，s03.sol 组合中的（该例子来自于 [原始题目](../../module-03/d04/) ）
- 本出修改的内容在MyToken合约中给出了正确与错误的transferAndCall调用方法，其本质区别就是在NFTMarket中以何种方式将Token转给卖家
    - IERC20(paymentToken).transferFrom(address(this), item.seller, item.price); 是错误的
    - IERC20(paymentToken).transfer(item.seller, item.price); 是正确的
    - 原因：**transferFrom(address(this), ...) 需要 address(this) 给自己批准了额度，但合约自己没有给自己授权，导致失败。**
        - 合约也无法去调用Token合约自己给自己授权，所以合约自己转账代币用 transfer，不要用 transferFrom
- 还有一个疑惑：为什么 IERC721(nftAddress).transferFrom(address(this), from, tokenId); 可以执行成功？
    - 在 ERC721 标准里，NFT 有一个 所有者（owner） 地址。合约自己持有这个 NFT（也就是 address(this) 是该 NFT 的 owner），所以：
        - 合约自身拥有该 NFT 的所有权
        - 合约调用 transferFrom(address(this), to, tokenId) 时，合约就是调用者本身（msg.sender == address(this)）
        - ERC721 的权限检查是
            - 要么 msg.sender == owner（就是合约自己）
            - 要么 msg.sender 被 owner 批准（approve）
        - 所以合约自己转自己拥有的 NFT 是合法且无需额外授权的。
    - ERC20 的 transferFrom 要求：调用者（msg.sender）必须获得 from 地址（这里是 address(this)）的 授权（approve） 才能转走代币。
        - 但是合约自己并没有给自己调用者授权（也就是自己没有给自己 approve），所以调用 transferFrom(address(this), ...) 会失败。
        - 通常，合约里如果想把自己持有的代币转给别人，直接调用 transfer 即可，不需要授权。

