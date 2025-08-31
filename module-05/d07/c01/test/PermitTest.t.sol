// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../src/MyToken.sol";
import "../src/TokenBank.sol";
import "../src/NFTMarket.sol";

/// 测试用 NFT
contract TestNFT is ERC721 {
    uint256 public nextId;

    constructor() ERC721("TestNFT", "TNFT") {}

    function mint(address to) external {
        _mint(to, nextId++);
    }
}

contract PermitTest is Test {
    MyToken token;  // 自定义的 ERC20 代币合约。
    TokenBank bank;  // 处理存款的合约。
    NFTMarket market;  // 用于列出和购买 NFT 的市场合约。
    TestNFT nft;  // 前面定义的 NFT 合约，用来测试 NFT 功能。

    // vm.addr(uint256 privateKey) 会帮你把一个假设的 privateKey 转换成对应的地址。
    // user
    address user = vm.addr(1);  // 测试中正常操作的用户。
    uint256 userPk = 1;  // user地址对应的私钥（模拟）
    // projectSigner
    address projectSigner = vm.addr(2);  // 项目签名地址
    uint256 projectPk = 2;  // projectSigner地址的私钥（模拟）
    // attacker
    address attacker = vm.addr(3);  // 模拟攻击者地址
    uint256 attackerPk = 3;  // attacker地址的私钥（模拟）

    function setUp() public {
        // init
        token = new MyToken(1e24); // 1M token
        bank = new TokenBank(address(token));
        market = new NFTMarket(address(token), projectSigner);
        nft = new TestNFT();

        // 给用户一些 token 和 nft
        token.transfer(user, 1e21); // 1000 token
        nft.mint(user);
    }

    // ---------------- TokenBank 测试 ----------------

    // 测试正常的 permitDeposit 功能，检查授权的用户是否能够成功存款
    function test_permitDeposit_success() public {
        uint256 amount = 1e20; // 100 token
        uint256 nonce = token.nonces(user);
        uint256 deadline = block.timestamp + 1 hours;

        // 整合签名数据
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                        ),
                        user,  // user：user地址
                        address(bank),
                        amount,
                        nonce,
                        deadline
                    )
                )
            )
        );

        // 签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);  // userPk：user私钥

        // 调用
        vm.prank(user);
        bank.permitDeposit(amount, deadline, v, r, s);

        assertEq(bank.balances(user), amount);
    }

    //  测试过期时 permitDeposit 应该失败。
    function test_permitDeposit_fail_expired() public {
        uint256 amount = 1e20;
        uint256 nonce = token.nonces(user);
        uint256 deadline = block.timestamp - 1; // 已过期

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(
                    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                    user,
                    address(bank),
                    amount,
                    nonce,
                    deadline
                ))
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);

        vm.prank(user);
        vm.expectRevert();
        bank.permitDeposit(amount, deadline, v, r, s);
    }

    // 测试使用无效签名时 permitDeposit 应该失败。
    function test_permitDeposit_fail_invalidSig() public {
        uint256 amount = 1e20;
        uint256 nonce = token.nonces(user);
        uint256 deadline = block.timestamp + 1 hours;

        // 整合数据
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                        ),
                        user,  // user：user地址
                        address(bank),
                        amount,
                        nonce,
                        deadline
                    )
                )
            )
        );

        // 攻击者签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(attackerPk, digest); // attackerPk：attacker私钥

        // 如果签名者不是 user，则 permitDeposit 应该抛出错误。
        vm.prank(user);
        vm.expectRevert();
        bank.permitDeposit(amount, deadline, v, r, s);
    }

    // 测试普通存款
    function test_deposit_normal() public {
        vm.startPrank(user);
        token.approve(address(bank), 50);  // 需要授权
        bank.deposit(50);
        vm.stopPrank();

        assertEq(bank.balances(user), 50);
    }

    // ---------------- NFTMarket 测试 ----------------
    // 测试正常的 permitBuy 操作，确保用户授权后可以成功购买 NFT。
    function test_permitBuy_success() public {
        // 用户list
        vm.startPrank(user);
        nft.approve(address(market), 0);  // nft授权
        market.list(address(nft), 0, 100);  // 上架
        token.approve(address(market), 100);  // token授权
        vm.stopPrank();

        // 签名
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 message = keccak256(
            abi.encodePacked(user, address(nft), uint256(0), deadline)  // user：user地址
        );
        bytes32 ethHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        // 签名；projectPk：用于签名的项目方私钥
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(projectPk, ethHash);  // projectPk：project私钥

        // 调用
        vm.prank(user);
        market.permitBuy(address(nft), 0, deadline, v, r, s);
        assertEq(nft.ownerOf(0), user);
    }

    // 测试时间过期签名的 permitBuy 失败。
    function test_permitBuy_fail_expired() public {
        // 用户list
        vm.startPrank(user);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, 100);
        token.approve(address(market), 100);
        vm.stopPrank();

        // 时间过期整合
        uint256 deadline = block.timestamp - 1; // 过期
        bytes32 message = keccak256(
            abi.encodePacked(user, address(nft), uint256(0), deadline)  // user：user地址
        );
        bytes32 ethHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        // 签名；projectPk：用于签名的项目方私钥
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(projectPk, ethHash);  // projectPk：project私钥

        // 调用
        vm.prank(user);
        vm.expectRevert("expired");  // 应该抛出的异常
        market.permitBuy(address(nft), 0, deadline, v, r, s);
    }

    // 测试非白名单签名的 permitBuy 失败。
    function test_permitBuy_fail_notWhitelisted() public {
        vm.startPrank(user);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, 100);
        token.approve(address(market), 100);
        vm.stopPrank();

        // 整合数据
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 message = keccak256(
            abi.encodePacked(user, address(nft), uint256(0), deadline)  // user：user地址
        );
        bytes32 ethHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        // 签名；attackerPk非项目方私钥签名。
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(attackerPk, ethHash); // attackerPk：攻击者私钥

        vm.prank(user);
        vm.expectRevert("not whitelisted");
        market.permitBuy(address(nft), 0, deadline, v, r, s);
    }

    // 普通上架购买
    function test_buy_normal() public {
        vm.startPrank(user);
        nft.approve(address(market), 0);
        market.list(address(nft), 0, 100);
        token.approve(address(market), 100);
        market.buy(address(nft), 0);
        vm.stopPrank();
        assertEq(nft.ownerOf(0), user);
    }

    // ---------------- 边界条件 ----------------
    // 测试存款金额为零时，permitDeposit 方法是否正常处理。
    function test_permitDeposit_zeroAmount() public {
        uint256 amount = 0;
        uint256 nonce = token.nonces(user);
        uint256 deadline = block.timestamp + 1 hours;

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256(
                            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                        ),
                        user,  // user：user地址
                        address(bank),
                        amount,
                        nonce,
                        deadline
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPk, digest);  // user：user私钥

        vm.prank(user);
        bank.permitDeposit(amount, deadline, v, r, s);
        assertEq(bank.balances(user), 0);  // 如果金额为零，存款应该为零。
    }
}
