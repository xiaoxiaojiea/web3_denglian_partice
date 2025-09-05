// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IPermit2} from "permit2/interfaces/IPermit2.sol";
import {ISignatureTransfer} from "permit2/interfaces/ISignatureTransfer.sol";

contract TestERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1_000_000 ether);
    }
}

contract TokenBankTest is Test {
    TokenBank public tokenBank;
    TestERC20 public testToken;

    address constant PERMIT2_ADDRESS =
        0x9681ecEa46960107877F4268437d1161a2A46f4c;

    uint256 userPk;
    address user;

    function setUp() public {
        (user, userPk) = makeAddrAndKey("user");
        testToken = new TestERC20("Test Token", "TEST");
        tokenBank = new TokenBank(address(testToken));

        // 给用户一些 token
        testToken.transfer(user, 1000 ether);

        // 用户 approve 给 Permit2
        vm.prank(user);
        testToken.approve(PERMIT2_ADDRESS, type(uint256).max);
    }

    function testDepositWithPermit2() public {
        uint256 amount = 100 ether;
        uint256 nonce = 0;
        uint256 deadline = block.timestamp + 1 hours;

        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer
            .PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: address(testToken),
                    amount: amount
                }),
                nonce: nonce,
                deadline: deadline
            });

        ISignatureTransfer.SignatureTransferDetails
            memory transferDetails = ISignatureTransfer
                .SignatureTransferDetails({
                    to: address(tokenBank),
                    requestedAmount: amount
                });

        // 生成 Permit2 签名
        bytes memory sig = _createPermit2Signature(
            permit,
            userPk,
            address(tokenBank)
        );

        // 调用 depositWithPermit2
        vm.prank(user);
        tokenBank.depositWithPermit2(amount, nonce, deadline, sig);

        // 验证
        assertEq(tokenBank.balanceOf(user), amount, "deposit record updated");
        assertEq(
            testToken.balanceOf(address(tokenBank)),
            amount,
            "bank received tokens"
        );
    }

    function _createPermit2Signature(
        ISignatureTransfer.PermitTransferFrom memory permit,
        uint256 privateKey,
        address spender
    ) internal view returns (bytes memory) {
        // 获取 Permit2 合约 DOMAIN_SEPARATOR
        bytes32 domainSeparator = IPermit2(PERMIT2_ADDRESS).DOMAIN_SEPARATOR();

        // 使用辅助函数生成 structHash
        bytes32 structHash = _hashPermitWithSpender(permit, spender);

        // EIP712 digest
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        // Forge vm.sign 生成签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _hashPermitWithSpender(
        ISignatureTransfer.PermitTransferFrom memory permit,
        address spender
    ) internal pure returns (bytes32) {
        bytes32 _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
            "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
        );

        bytes32 tokenPermissionsHash = keccak256(
            abi.encode(
                keccak256("TokenPermissions(address token,uint256 amount)"),
                permit.permitted.token,
                permit.permitted.amount
            )
        );

        return
            keccak256(
                abi.encode(
                    _PERMIT_TRANSFER_FROM_TYPEHASH,
                    tokenPermissionsHash,
                    spender,
                    permit.nonce,
                    permit.deadline
                )
            );
    }

    function testCheckPermit2Code() public {
        uint256 size = PERMIT2_ADDRESS.code.length;
        console.log("Permit2 code size:", size);
        assertGt(size, 0, "Permit2 not deployed on forked chain");
    }
    
}
