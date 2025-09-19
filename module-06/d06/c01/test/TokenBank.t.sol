// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../src/MyToken.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {
    MyToken public token;
    TokenBank public bank;
    address user = address(0x1);

    function setUp() public {
        token = new MyToken(1000 ether);
        bank = new TokenBank(address(token));

        // 给用户分配代币
        token.transfer(user, 500 ether);
    }

    /// @dev 测试普通存款和取款
    function test_DepositAndWithdraw() public {
        vm.startPrank(user);

        // 先授权
        token.approve(address(bank), 100 ether);

        // 存款
        bank.deposit(100 ether);
        assertEq(bank.balances(user), 100 ether);

        // 取款
        bank.withdraw(50 ether);
        assertEq(bank.balances(user), 50 ether);

        vm.stopPrank();
    }

    /// @dev 测试 multicall 存款
    function test_MulticallDeposit() public {
        vm.startPrank(user);

        token.approve(address(bank), 200 ether);

        // 编码 deposit(100 ether) 和 deposit(50 ether)
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(bank.deposit.selector, 100 ether);
        calls[1] = abi.encodeWithSelector(bank.deposit.selector, 50 ether);

        bank.multicall(calls);

        assertEq(bank.balances(user), 150 ether);

        vm.stopPrank();
    }

}
