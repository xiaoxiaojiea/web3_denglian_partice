// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Vesting.sol";
import "../src/MyToken.sol";

contract VestingTest is Test {
    Vesting public vesting;
    MyToken public token;
    address public beneficiary = address(0xBEEF);
    address public owner = address(this);
    uint256 public constant TOTAL_SUPPLY = 1_000_000 ether;
    uint256 public constant MONTH = 30 days;

    function setUp() public {
        token = new MyToken("MyToken", "MTK");
        token.mint(owner, TOTAL_SUPPLY);
        vesting = new Vesting(token, beneficiary);
        
        // 将 1_000_000 代币转入线性解锁合约
        token.transfer(address(vesting), TOTAL_SUPPLY);
    }

    // 检查状态
    function testInitialState() public {
        assertEq(vesting.beneficiary(), beneficiary);
        assertEq(vesting.start(), block.timestamp);
        assertEq(vesting.cliff(), block.timestamp + 12 * MONTH);
        assertEq(vesting.vestingEnd(), block.timestamp + 36 * MONTH);
        assertEq(vesting.released(), 0);
    }

    // 悬崖期测试
    function testCliffNoRelease() public {
        // 悬崖期前11个月29天：应返回0
        vm.warp(block.timestamp + 11 * MONTH + 29 days);
        assertEq(vesting.releasableAmount(), 0);
        
        // 悬崖期结束瞬间：应返回0（时间差为0）
        vm.warp(vesting.cliff()); // 正好悬崖期结束
        assertEq(vesting.releasableAmount(), 0); // 应该为0，因为timeSinceCliff = 0
        
        // 悬崖期后1秒：应返回0（不满1个月）
        vm.warp(vesting.cliff() + 1);
        assertEq(vesting.releasableAmount(), 0); // 仍然为0，因为不满1个月
        
        // 悬崖期后1个月：应解锁1/24的代币
        vm.warp(vesting.cliff() + MONTH);
        uint256 expectedFirstMonth = TOTAL_SUPPLY / 24;
        assertEq(vesting.releasableAmount(), expectedFirstMonth);
    }

    //  按月释放测试
    function testMonthlyRelease() public {
        // 悬崖期后1个月：解锁1/24
        vm.warp(vesting.cliff() + MONTH);
        uint256 expectedFirstMonth = TOTAL_SUPPLY / 24;
        assertEq(vesting.releasableAmount(), expectedFirstMonth);
        
        // 受益人提取第一个月代币
        vm.prank(beneficiary);
        vesting.release();
        assertEq(token.balanceOf(beneficiary), expectedFirstMonth);
        assertEq(vesting.released(), expectedFirstMonth);
        
        // 悬崖期后6个月：应累计解锁6/24
        vm.warp(vesting.cliff() + 6 * MONTH);
        uint256 expectedSixMonths = (TOTAL_SUPPLY * 6) / 24;
        uint256 releasable = vesting.releasableAmount();
        // 减去已经释放的1个月，应该还可以释放5个月
        assertEq(releasable, expectedSixMonths - expectedFirstMonth);
        
        // 再次提取时只能提取剩余5个月的量
        vm.prank(beneficiary);
        vesting.release();
        assertEq(token.balanceOf(beneficiary), expectedSixMonths);
        assertEq(vesting.released(), expectedSixMonths);
    }

    // 完全释放测试
    function testFullRelease() public {
        // 直接跳到完全解锁时间点
        vm.warp(vesting.cliff() + 24 * MONTH);
        
        // 验证可以提取全部代币
        vm.prank(beneficiary);
        vesting.release();
        
        // 检查余额和已释放金额的正确性
        assertEq(token.balanceOf(beneficiary), TOTAL_SUPPLY);
        assertEq(vesting.released(), TOTAL_SUPPLY);
    }

    // 权限测试
    function testOnlyBeneficiaryCanRelease() public {
        vm.warp(vesting.cliff() + MONTH);
        
        // 非受益人调用应该失败
        vm.expectRevert("only beneficiary");
        vesting.release();
        
        // 受益人调用应该成功
        vm.prank(beneficiary);
        vesting.release();
    }

    // 精确时间测试
    function testPreciseTiming() public {
        uint256 cliff = vesting.cliff();
        
        // 悬崖期前1秒：0解锁
        vm.warp(cliff - 1);
        assertEq(vesting.releasableAmount(), 0);
        
        // 悬崖期开始：0解锁（时间差为0）
        vm.warp(cliff);
        assertEq(vesting.releasableAmount(), 0); // timeSinceCliff = 0
        
        // 悬崖期后1个月减1秒：0解锁（不满整月）
        vm.warp(cliff + MONTH - 1);
        assertEq(vesting.releasableAmount(), 0); // 仍然不满1个月
        
        // 悬崖期后正好1个月：解锁1/24
        vm.warp(cliff + MONTH);
        assertEq(vesting.releasableAmount(), TOTAL_SUPPLY / 24); // 第1个月解锁
        
        // 悬崖期后正好2个月：解锁2/24
        vm.warp(cliff + 2 * MONTH);
        assertEq(vesting.releasableAmount(), (TOTAL_SUPPLY * 2) / 24); // 前2个月解锁
    }

}