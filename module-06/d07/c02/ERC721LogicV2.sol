// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ERC721 Logic V2 (在 V1 基础上新增功能)
contract ERC721LogicV2 {
    // 存储布局必须和 V1 一致，新增变量只能往后加
    string public name;
    string public symbol;
    mapping(uint256 => address) internal owners;
    mapping(address => uint256) internal balances;
    uint256 public totalSupply;

    // V2 新增
    string public baseURI;
    uint256 public version;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// V2 新增初始化（升级时用）
    function initializeV2(string memory _baseURI) external {
        require(version == 0, "Already initialized V2");
        baseURI = _baseURI;
        version = 2;
    }

    function mint(address to, uint256 tokenId) external {
        require(to != address(0), "Invalid address");
        require(owners[tokenId] == address(0), "Already minted");

        owners[tokenId] = to;
        balances[to] += 1;
        totalSupply += 1;

        emit Transfer(address(0), to, tokenId);
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), "Not minted");
        return owner;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    // V2 新增：tokenURI
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(owners[tokenId] != address(0), "Not minted");
        return string(abi.encodePacked(baseURI, _toString(tokenId)));
    }

    // 内部工具函数
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
