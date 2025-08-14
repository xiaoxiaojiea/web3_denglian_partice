// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/bank.sol";

contract CounterTest is Test {
    Bank public bank;
    address public alice = address(0x1);  // 如果不给后边的内容，那他的地址就是0
    address public bob = address(0x2);
    address public carol = address(0x3);
    address public dave  = address(0x4);

    function setUp() public {
        bank = new Bank();
    }

    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确
    function test_deposit_success() public {
        // 给 alice 转 10 eth
        vm.deal(alice, 10 ether);

        // 查询alice之前的余额
        uint pre_balance = bank.balances(alice);  

        // 切换调用者进行存款
        vm.prank(alice);  
        bank.deposit{value: 5 ether}();  // Alice 存入 5 ETH

        // 查询存款后余额
        uint256 post_balance = bank.balances(alice);

        // 断言存款正确增加
        assertEq(post_balance, pre_balance + 5 ether);
    }

    // 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
    //  user1
    function test_top3_user1_success() public {
        // ============================== alice存款
        vm.deal(alice, 10 ether);
        vm.prank(alice);  
        bank.deposit{value: 5 ether}();  // Alice 存入 5 ETH

        // ============================== 检查alice是否top3
        (address[3] memory addrs, uint256[3] memory amts) = bank.getTop3();

        assertEq(addrs[0], alice);
        assertEq(amts[0], 5 ether);
    }

    //  user2
    function test_top3_user2_success() public {
        // ============================== alice bob存款
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);

        vm.prank(alice);  
        bank.deposit{value: 5 ether}();  // Alice 存入 5 ETH

        vm.prank(bob);
        bank.deposit{value: 3 ether}();

        // ============================== 检查alice是否top3
        (address[3] memory addrs, uint256[3] memory amts) = bank.getTop3();

        // Alice 存款最高
        assertEq(addrs[0], alice);
        assertEq(amts[0], 5 ether);

        // Bob 存款次高
        assertEq(addrs[1], bob);
        assertEq(amts[1], 3 ether);
    }

    //  user3
    function test_top3_user3_success() public {
        // ============================== alice bob carol存款
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(carol, 10 ether);

        vm.prank(alice);  
        bank.deposit{value: 5 ether}();  // Alice 存入 5 ETH
        vm.prank(bob);
        bank.deposit{value: 3 ether}();
        vm.prank(carol);
        bank.deposit{value: 7 ether}();

        // ============================== 检查alice是否top3
        (address[3] memory addrs, uint256[3] memory amts) = bank.getTop3();

        // 排序不保证顺序，只检查 top3 数值
        bool foundAlice = false;
        bool foundBob = false;
        bool foundCarol = false;

        for (uint i = 0; i < 3; i++) {
            if (addrs[i] == alice) { assertEq(amts[i], 5 ether); foundAlice = true; }
            if (addrs[i] == bob)   { assertEq(amts[i], 3 ether); foundBob = true; }
            if (addrs[i] == carol) { assertEq(amts[i], 7 ether); foundCarol = true; }
        }
        assertTrue(foundAlice && foundBob && foundCarol);
    }

    //  user4
    function test_top3_user4_success() public {
        // ============================== alice bob carol dave存款
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(carol, 10 ether);
        vm.deal(dave, 10 ether);

        vm.prank(alice);  
        bank.deposit{value: 5 ether}();  // Alice 存入 5 ETH
        vm.prank(bob);
        bank.deposit{value: 3 ether}();
        vm.prank(carol);
        bank.deposit{value: 7 ether}();
        vm.prank(dave);
        bank.deposit{value: 6 ether}();

        // ============================== 检查alice是否top3
        (address[3] memory addrs, uint256[3] memory amts) = bank.getTop3();

        // 期望 top3: carol (7), dave (6), alice (5)
        bool foundAlice = false;
        bool foundBob = false;
        bool foundCarol = false;
        bool foundDave = false;

        for (uint i = 0; i < 3; i++) {
            if (addrs[i] == alice) { assertEq(amts[i], 5 ether); foundAlice = true; }
            if (addrs[i] == bob)   { foundBob = true; }
            if (addrs[i] == carol) { assertEq(amts[i], 7 ether); foundCarol = true; }
            if (addrs[i] == dave)  { assertEq(amts[i], 6 ether); foundDave = true; }
        }

        assertTrue(foundAlice && !foundBob && foundCarol && foundDave);
    }

    //  同一个用户多次存款
    function test_top3_user_multi_success() public {
        // ============================== alice bob carol dave存款
        vm.deal(alice, 10 ether);

        // vm.prank(alice);  // vm.prank(alice) 只会影响下一笔交易，所以第二次调用 bank.deposit{value: 2 ether}(); 不再是 Alice 调用，导致存款不会计入 Alice。

        vm.startPrank(alice);
        bank.deposit{value: 3 ether}();  // Alice 存入 3 ETH
        bank.deposit{value: 2 ether}();  // Alice 存入 2 ETH
        vm.stopPrank();

        // ============================== 检查alice是否top3
        (address[3] memory addrs, uint256[3] memory amts) = bank.getTop3();

        // Alice 应该在 top3 中，金额为 5 ether
        bool foundAlice = false;
        for (uint i = 0; i < 3; i++) {
            if (addrs[i] == alice) { assertEq(amts[i], 5 ether); foundAlice = true; }
        }
        assertTrue(foundAlice);
    }

    function test_onlyOwner_canWithdraw() public {
        // Alice存
        vm.deal(alice, 10 ether);
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        // ==================== 非管理员尝试提取 Alice 的余额
        vm.prank(bob);
        vm.expectRevert("Not owner");
        bank.withdraw(alice);

        // ==================== 管理员提取 Alice 的余额
        uint256 ownerBalanceBefore = address(this).balance; // 测试合约地址当作管理员
        vm.prank(address(this));  // bank合约的owner就是当前合约（因为是当前合约部署的bank）
        bank.withdraw(alice);  // 必须要有 receive() 函数，不然无法接收eth
        uint256 ownerBalanceAfter = address(this).balance;
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 5 ether);

        // Alice 的余额清零
        uint256 aliceBalance = bank.balances(alice);
        assertEq(aliceBalance, 0);
    }

    // 允许测试合约接收 ETH
    receive() external payable {}

}
