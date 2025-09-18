// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is ERC721 {
    uint private _ids = 0;

    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to) external returns (uint256) {
        uint256 id = _ids;
        _mint(to, id);

        _ids++;

        return id;
    }
}
