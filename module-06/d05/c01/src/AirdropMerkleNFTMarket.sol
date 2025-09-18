// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {TestNFT} from "./TestNFT.sol";

contract AirdropMerkleNFTMarket {
    IERC20 public immutable token;
    TestNFT public immutable nft;
    bytes32 public immutable merkleRoot;

    address public owner;
    uint256 public price = 1e18; // 1 token

    // 因为 Merkle proof 可以重复使用，不能防止一个人mint多次，所以需要增加一个已mint记录，防止多次mint
    mapping(address => bool) public claimed;

    constructor(IERC20 _token, TestNFT _nft, bytes32 _merkleRoot) {
        token = _token;
        nft = _nft;
        merkleRoot = _merkleRoot;

        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    // === Multicall ===
    // 一次调用合约的多个方法
    //      data：是一个个合约调用的字节码list
    function multicall(bytes[] calldata data) external {
        // 遍历一个个合约调用的字节码
        for (uint i = 0; i < data.length; i++) {
            // delegatecall：
            //      保留 msg.sender 和存储上下文，适合组合操作（比如 permit + claimNFT）。
            //      delegatecall 会完全执行调用数据，如果调用错误，整个事务 revert。
            (bool ok, bytes memory res) = address(this).delegatecall(data[i]);
            require(ok, string(res));
        }
    }

    // === Step1: permit 预授权 ===
    // 用户在前端签名 approve 授权交易，合约通过 permit 使用签名直接获得 transferFrom 权限
    //      这样用户无需先 approve 再调用 claimNFT，可以合并为一次交易
    function permitPrePay(
        address user,  // 授权用户地址
        uint256 value,  // 授权金额
        uint256 deadline,  // 签名过期时间
        uint8 v, bytes32 r, bytes32 s  // 用户签名的 ECDSA 数据
    ) external {
        IERC20Permit(address(token)).permit(user, address(this), value, deadline, v, r, s);
    }

    // === Step2: claim NFT ===
    function claimNFT(address user, bytes32[] calldata proof) external {
        // proof 是 Merkle proof，前端生成。

        require(!claimed[user], "Already claimed");

        // 白名单验证
        bytes32 leaf = keccak256(abi.encodePacked(user));  // 用户地址哈希
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not whitelisted");  // 验证用户是否在白名单中

        // 支付代币（半价）(前提是用户已经使用 permit 或 approve 授权过)
        require(token.transferFrom(user, owner, price / 2), "pay failed");

        claimed[user] = true; // 标记已领取

        // 铸造 NFT
        nft.mint(user);
    }

}
