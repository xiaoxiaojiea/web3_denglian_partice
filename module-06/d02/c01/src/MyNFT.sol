// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyNFT is ERC721URIStorage, Ownable {
    uint256 private _nextTokenId;  // 当前NFT的idx
    string public metaDataURI_ = "ipfs://QmNrKkmZkJ3ryt5Ty5z6AxpvXyTC9TAovtFaqqMo6pvZRy";  // nft_matedate.json文件的CID

    constructor(string memory tokenName, string memory tokenSymbol)
        ERC721(tokenName, tokenSymbol)
        Ownable(msg.sender)
    {
        _nextTokenId = 0;  // NFT编号从0开始
    }

    // msg.sender为自己铸造NFT
    function mint() external {
        uint256 tokenId = _nextTokenId++;  // NFT ID
        _safeMint(msg.sender, tokenId);  // 调用ERC721类的mint方法，为地址to mint一个id为tokenId的NFT
        // 为该NFT设置meat信息
        _setTokenURI(tokenId, metaDataURI_);
    }

}
