// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 对应NFT market支持的回调购买接口
interface IERC20Receiver {
    // 回调购买方法
    function tokensReceived(address from, uint256 amount, bytes calldata data) external;
}

contract MyToken is ERC20, Ownable {

    // token的基本信息
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) 
        ERC20(_name, _symbol) 
        Ownable(msg.sender) {

        _mint(msg.sender, _initialSupply);
    }

    // token的回调购买nft方法
    function transferAndCall(address nftMarketAddress, uint256 amount, bytes calldata data) external returns (bool) {
        // 调用者将自己的token转移到地址to（该地址应该是nft market合约地址，因为token到了合约地址之后合约会分发给nft卖家的）
        _transfer(msg.sender, nftMarketAddress, amount);

        // 确保to地址是nft market合约地址
        if (nftMarketAddress.code.length > 0) {  // 大于 0，说明 nftMarketAddress 是合约地址
            // 调用nft market的回调购买方法
            IERC20Receiver(nftMarketAddress).tokensReceived(msg.sender, amount, data);
        }

        return true;
    }

    // 编码函数（因为transferAndCall中使用到了calldata数据，所以这里准备一个编码函数，方便使用而已）
    function encodeNFTData(address nftAddress, uint256 tokenId) external pure returns (bytes memory) {
        return abi.encode(nftAddress, tokenId);
    }
    
}
