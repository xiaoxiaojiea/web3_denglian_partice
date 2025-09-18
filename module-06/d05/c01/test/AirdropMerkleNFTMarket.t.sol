// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TestToken.sol";
import "../src/TestNFT.sol";
import "../src/AirdropMerkleNFTMarket.sol";

import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract AirdropMerkleNFTMarketTest is Test {
    TestToken token;
    TestNFT nft;
    AirdropMerkleNFTMarket market;

    // 为用户绑定固定私钥和地址
    uint256 user1Pk = 0xA11CE;
    uint256 user2Pk = 0xB0B0;
    uint256 user3Pk = 0xC0C0;
    uint256 user4Pk = 0xD0D0;
    uint256 user5Pk = 0xE0E0;

    // 5个白名单用户
    address user1;
    address user2;
    address user3;
    address user4;
    address user5;

    // 非白名单用户
    uint256 nonWhitelistPk = 0xF0F0;
    address nonWhitelistedUser;

    bytes32 merkleRoot;
    mapping(address => bytes32[]) proofs;

    function setUp() public {
        // 生成地址
        user1 = vm.addr(user1Pk);
        user2 = vm.addr(user2Pk);
        user3 = vm.addr(user3Pk);
        user4 = vm.addr(user4Pk);
        user5 = vm.addr(user5Pk);
        nonWhitelistedUser = vm.addr(nonWhitelistPk);

        // 创建两个合约
        token = new TestToken();
        nft = new TestNFT();

        // 创建白名单地址数组
        address[] memory whitelist = new address[](5);
        whitelist[0] = user1;
        whitelist[1] = user2;
        whitelist[2] = user3;
        whitelist[3] = user4;
        whitelist[4] = user5;

        // 拿到 Merkle 树叶子
        bytes32[] memory leaves = new bytes32[](whitelist.length);
        for (uint256 i = 0; i < whitelist.length; i++) {
            leaves[i] = keccak256(abi.encodePacked(whitelist[i]));
        }

        // 构建 Merkle 树
        merkleRoot = buildMerkleRoot(leaves);

        // 为每个用户生成 proof
        for (uint256 i = 0; i < whitelist.length; i++) {
            proofs[whitelist[i]] = getProof(leaves, i);
        }

        // 拿着 Merkle 树来构建空投合约
        market = new AirdropMerkleNFTMarket(token, nft, merkleRoot);

        // 给每个用户转账代币
        token.transfer(user1, 10 ether);
        token.transfer(user2, 10 ether);
        token.transfer(user3, 10 ether);
        token.transfer(user4, 10 ether);
        token.transfer(user5, 10 ether);
        token.transfer(nonWhitelistedUser, 10 ether);
    }

    // OpenZeppelin 的 MerkleProof 默认逻辑是 有序拼接，也就是：
    //      if (a <= b) {
    //          hash = keccak256(abi.encodePacked(a, b));
    //      } else {
    //          hash = keccak256(abi.encodePacked(b, a));
    //      }
    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return
            a < b
                ? keccak256(abi.encodePacked(a, b))
                : keccak256(abi.encodePacked(b, a));
    }

    // 构建 Merkle 树（手写的Merkle Tree构建工具，好像OpenZeppelin中也有库）
    function buildMerkleRoot(
        bytes32[] memory leaves  // Merkle 树叶子哈希
    ) internal pure returns (bytes32) {

        if (leaves.length == 0) return bytes32(0);

        // 过程：
        //      1，每次循环，把 leaves 两两配对，拼成父节点（_hashPair）。
        //      2，如果叶子数是奇数，最后一个直接晋级（拷贝到上层）。
        //      3，更新 leaves = next，继续合并，直到只剩一个节点。
        // 输出：整个树的根节点 merkleRoot 哈希。
        while (leaves.length > 1) {
            uint256 n = (leaves.length + 1) / 2;  // 上一轮两两合并后剩余多少叶子节点
            bytes32[] memory next = new bytes32[](n);  // 申请存储空间

            // 相邻两两叶子节点合并为一个根节点，存储在新空间中
            for (uint256 i = 0; i < leaves.length; i += 2) {
                if (i + 1 < leaves.length) {
                    next[i / 2] = _hashPair(leaves[i], leaves[i + 1]);
                } else {
                    next[i / 2] = leaves[i];
                }
            }

            // 下一轮剩余的叶子节点
            leaves = next;
        }

        // 返回
        return leaves[0];
    }

    // 生成 Merkle proof（输出目标叶子节点的 Merkle Proof（兄弟节点哈希数组））
    function getProof(
        bytes32[] memory leaves,  // 全部叶子list
        uint256 index  // 目标叶子的位置
    ) internal pure returns (bytes32[] memory) {
        require(index < leaves.length, "Index out of bounds");

        // 过程：
        //      1，遍历整棵树，逐层向上。
        //      2，每一层如果当前 index 对应的叶子和它的兄弟被配对：
        //          - 取出 兄弟节点 sibling，加入 proof。
        //          - 把 index 更新为父节点的位置 i/2。
        //      3，如果是最后一个孤儿节点（没有兄弟），直接晋级（不加 proof）。
        //      4，循环直到到达根节点。

        /** 举例：叶子 [L0, L1, L2, L3]，想证明 L2 属于树：
         * 第一层：
         *      Pair0 = hash(L0, L1)
         *      Pair1 = hash(L2, L3)
         *      Proof 收集到：L3 （L2 的兄弟）
         * 第二层：
         *      Root = hash(Pair0, Pair1)
         *      Proof 收集到：Pair0 （Pair1 的兄弟）
         * 最终 proof = [L3, Pair0]。
         * 
         * 
         * 在验证时：
         *      hash(L2, L3) => Pair1
         *      hash(Pair0, Pair1) => Root
         * 和合约存的 Merkle Root 一致
         */

        bytes32[] memory proof = new bytes32[](0);
        while (leaves.length > 1) {
            uint256 n = (leaves.length + 1) / 2;
            bytes32[] memory next = new bytes32[](n);
            for (uint256 i = 0; i < leaves.length; i += 2) {
                if (i + 1 < leaves.length) {
                    next[i / 2] = _hashPair(leaves[i], leaves[i + 1]);
                    if (i == index || i + 1 == index) {
                        // sibling
                        bytes32 sibling = (i == index)
                            ? leaves[i + 1]
                            : leaves[i];
                        // 扩展 proof 数组
                        bytes32[] memory newProof = new bytes32[](
                            proof.length + 1
                        );
                        for (uint256 j = 0; j < proof.length; j++) {
                            newProof[j] = proof[j];
                        }
                        newProof[proof.length] = sibling;
                        proof = newProof;
                        index = i / 2;
                    }
                } else {
                    next[i / 2] = leaves[i];
                    if (i == index) {
                        index = i / 2;
                    }
                }
            }
            leaves = next;
        }
        return proof;
    }

    // 测试白名单用户正常购买
    function testWhitelistedUserCanClaimNFT() public {
        vm.startPrank(user1);

        // 先授权
        token.approve(address(market), 1 ether);

        // 然后 claim NFT
        market.claimNFT(user1, proofs[user1]);

        assertEq(nft.ownerOf(0), user1);
        assertEq(token.balanceOf(user1), 9.5 ether); // 支付了 0.5 ether (半价)
        vm.stopPrank();
    }

    // 测试所有白名单用户都能购买
    function testAllWhitelistedUsersCanClaim() public {
        address[] memory users = new address[](5);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;
        users[3] = user4;
        users[4] = user5;

        for (uint256 i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            token.approve(address(market), 1 ether);
            market.claimNFT(users[i], proofs[users[i]]);
            vm.stopPrank();

            assertEq(nft.ownerOf(i), users[i]);
        }
    }

    // 测试非白名单用户不能购买
    function testNonWhitelistedUserCannotClaim() public {
        vm.startPrank(nonWhitelistedUser);
        token.approve(address(market), 1 ether);

        // 应该会失败，因为不在白名单中
        vm.expectRevert("Not whitelisted");
        market.claimNFT(nonWhitelistedUser, proofs[user1]); // 使用错误的 proof

        vm.stopPrank();
    }

    // 签名工具函数
    function getPermitSignature(
        uint256 privateKey,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal returns (uint8 v, bytes32 r, bytes32 s) {
        // 获取 nonce
        uint256 nonce = token.nonces(owner);

        // 构建 permit 类型的哈希
        bytes32 permitHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );

        // 构建 EIP-712 域分隔符
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();

        // 构建最终哈希
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, permitHash)
        );

        // 使用 Foundry 的 cheatcode 来签名
        (v, r, s) = vm.sign(privateKey, digest);
    }

    // 测试使用 multicall 组合 permit + claimNFT
    function testMulticallWithPermitAndClaim() public {
        vm.startPrank(user1);

        // 生成 permit 签名
        (uint8 v, bytes32 r, bytes32 s) = getPermitSignature(
            user1Pk,
            user1,
            address(market),
            1 ether,
            block.timestamp + 1 hours
        );

        // 构建 multicall 数据
        bytes[] memory calls = new bytes[](2);

        // permit 调用
        calls[0] = abi.encodeWithSelector(
            AirdropMerkleNFTMarket.permitPrePay.selector,
            user1,
            1 ether,
            block.timestamp + 1 hours,
            v, r, s
        );

        // claimNFT 调用
        calls[1] = abi.encodeWithSelector(
            AirdropMerkleNFTMarket.claimNFT.selector,
            user1,
            proofs[user1]
        );

        // 执行 multicall
        market.multicall(calls);

        assertEq(nft.ownerOf(0), user1);
        vm.stopPrank();
    }

    // 测试支付失败的情况
    function testClaimFailsWithoutApproval() public {
        vm.startPrank(user1);

        // 不进行 approve
        vm.expectRevert();  // 具体报错授权不足的
        market.claimNFT(user1, proofs[user1]);

        vm.stopPrank();
    }

    // 测试重复 claim
    function testCannotClaimTwice() public {
        vm.startPrank(user1);
        token.approve(address(market), 1 ether);
        market.claimNFT(user1, proofs[user1]);

        // 第二次应该失败，因为 proof 只能使用一次（但实际 Merkle proof 可以重复使用）
        //      所以合约中增加了控制，尽管多次验证可以通过，但是其他逻辑约束不可以继续mint
        token.approve(address(market), 1 ether);
        vm.expectRevert("Already claimed"); // 因为用户余额不足（第一次已经支付了）
        market.claimNFT(user1, proofs[user1]);

        vm.stopPrank();
    }

    // 测试错误的 proof
    function testClaimFailsWithWrongProof() public {
        vm.startPrank(user1);
        token.approve(address(market), 1 ether);

        // 使用错误的 proof（user2 的 proof）
        vm.expectRevert("Not whitelisted");
        market.claimNFT(user1, proofs[user2]);

        vm.stopPrank();
    }

    // 测试空 proof
    function testClaimFailsWithEmptyProof() public {
        vm.startPrank(user1);
        token.approve(address(market), 1 ether);

        bytes32[] memory emptyProof = new bytes32[](0);
        vm.expectRevert("Not whitelisted");
        market.claimNFT(user1, emptyProof);

        vm.stopPrank();
    }
}
