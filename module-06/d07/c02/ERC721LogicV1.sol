// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC721 Logic V1 (最简版)
contract ERC721LogicV1 {
    // 存储布局（必须保持顺序和位置）
    string public name;
    string public symbol;
    mapping(uint256 => address) internal owners;
    mapping(address => uint256) internal balances;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// 初始化函数（只能调用一次）
    function initialize(string memory _name, string memory _symbol) external {
        require(bytes(name).length == 0 && bytes(symbol).length == 0, "Already initialized");
        name = _name;
        symbol = _symbol;
        totalSupply = 0;
    }

    /// mint
    function mint(address to, uint256 tokenId) external {
        require(to != address(0), "Invalid address");
        require(owners[tokenId] == address(0), "Already minted");

        owners[tokenId] = to;
        balances[to] += 1;
        totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }

    /// ownerOf
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "Not minted");
        return owner;
    }

    /// balanceOf
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}
