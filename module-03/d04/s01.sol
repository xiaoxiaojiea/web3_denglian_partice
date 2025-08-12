// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    // 当前NFT的idx
    uint256 private _nextTokenId;
    // nft_matedate.json文件的CID
    string public metaDataURI_ = "ipfs://QmNrKkmZkJ3ryt5Ty5z6AxpvXyTC9TAovtFaqqMo6pvZRy";

    constructor(string memory tokenName, string memory tokenSymbol)
        ERC721(tokenName, tokenSymbol)
        Ownable(msg.sender)
    {
        _nextTokenId = 0;  // NFT编号从0开始
    }

    // 铸造 NFT，只有合约拥有者可执行，所有NFT默认用相同MetaData URI
    function mint(address to) external onlyOwner {
        uint256 tokenId = _nextTokenId++;  // NFT ID
        // 调用ERC721类的mint方法，为地址to mint一个id为tokenId的NFT
        _safeMint(to, tokenId);
        // 为该NFT设置meat信息
        _setTokenURI(tokenId, metaDataURI_);
    }

}
