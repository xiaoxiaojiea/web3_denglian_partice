// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet multiSig;
    address[] owners;
    uint256 threshold = 2;
    
    // 定义测试地址
    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address nonOwner = address(0x4);
    address recipient = address(0x5);

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);
        
        vm.prank(owner1);  // 切换合约调用者
        multiSig = new MultiSigWallet(owners, threshold);
        
        // 给多签钱包发送一些ETH
        vm.deal(address(multiSig), 10 ether);
    }

    // 部署测试
    function testDeployment() public {
        assertEq(multiSig.threshold(), threshold);  // 确认门槛值正确设置为2
        assertTrue(multiSig.isOwner(owner1));  // 确认三个地址都是所有者
        assertTrue(multiSig.isOwner(owner2));
        assertTrue(multiSig.isOwner(owner3));
        assertFalse(multiSig.isOwner(nonOwner));  // 确认非所有者地址不是所有者
    }

    // 提交交易测试
    function testSubmitTransaction() public {
        // 切换o1账户
        vm.prank(owner1);
        uint256 txId = multiSig.submitTransaction(recipient, 1 ether, "");  // owner1提交向recipient转账1 ETH的交易
        
        // 检查交易详情是否正确存储
        (address to, uint256 value, bytes memory data, bool executed, uint256 confirmations) = multiSig.getTransaction(txId);
        
        assertEq(to, recipient);
        assertEq(value, 1 ether);
        assertEq(executed, false);
        assertEq(confirmations, 1); // 提交者自动确认
    }

    // 确认交易测试
    function testConfirmTransaction() public {
        // owner1提交交易
        vm.prank(owner1);
        uint256 txId = multiSig.submitTransaction(recipient, 1 ether, "");

        // owner2确认交易
        vm.prank(owner2);
        multiSig.confirmTransaction(txId);

        // 检查两个所有者都确认了交易
        assertTrue(multiSig.isConfirmed(txId, owner1));
        assertTrue(multiSig.isConfirmed(txId, owner2));
        // 确认总确认数为2
        assertEq(multiSig.getConfirmationCount(txId), 2);
    }

    // 执行交易测试
    function testExecuteTransaction() public {
        // 记录recipient的初始余额
        uint256 initialBalance = recipient.balance;
        
        // owner1提交转账交易
        vm.prank(owner1);
        uint256 txId = multiSig.submitTransaction(recipient, 1 ether, "");

        // owner2确认交易（达到门槛2，自动执行该交易）
        vm.prank(owner2);
        multiSig.confirmTransaction(txId); // 达到门槛，自动执行

        // 检查交易状态变为已执行
        (,,, bool executed,) = multiSig.getTransaction(txId);
        assertTrue(executed);

        // 确认recipient收到1 ETH
        assertEq(recipient.balance, initialBalance + 1 ether);
    }

    // 撤销确认测试
    function testRevokeConfirmation() public {
        // owner1提交并自动确认交易
        vm.prank(owner1);
        uint256 txId = multiSig.submitTransaction(recipient, 1 ether, "");

        // owner1撤销确认
        vm.prank(owner1);
        multiSig.revokeConfirmation(txId);

        // 检查确认状态被移除
        assertFalse(multiSig.isConfirmed(txId, owner1));
        // 确认总数归零
        assertEq(multiSig.getConfirmationCount(txId), 0);
    }

    // 权限控制测试
    function testNonOwnerCannotSubmit() public {
        // 非所有者尝试提交交易
        vm.prank(nonOwner);
        vm.expectRevert("Not an owner");  // 预期会回滚并显示"Not an owner"
        multiSig.submitTransaction(recipient, 1 ether, "");
    }

    // 接收ETH测试
    function testReceiveEther() public {
        // 记录多签钱包初始余额
        uint256 initialBalance = address(multiSig).balance;
        
        // 给owner1分配5 ETH
        vm.deal(owner1, 5 ether);

        // owner1向多签钱包转账2 ETH
        vm.prank(owner1);
        (bool success,) = address(multiSig).call{value: 2 ether}("");
        
        // 确认转账成功且余额正确
        assertTrue(success);
        assertEq(address(multiSig).balance, initialBalance + 2 ether);
    }

    // 合约调用测试
    function testContractCall() public {
        // 部署测试合约
        TestContract testContract = new TestContract();
        
        // 编码调用setValue(42)的calldata
        bytes memory data = abi.encodeWithSignature("setValue(uint256)", 42);
        
        // 提交调用测试合约的交易
        vm.prank(owner1);
        uint256 txId = multiSig.submitTransaction(address(testContract), 0, data);
        // 确认并执行交易
        vm.prank(owner2);   
        multiSig.confirmTransaction(txId);

        // 检查测试合约的值被正确设置为42
        assertEq(testContract.getValue(), 42);
    }
}

// 测试合约，验证多签钱包可以正确执行任意合约调用
contract TestContract {
    uint256 public value;
    
    function setValue(uint256 _value) public {
        value = _value;
    }
    
    function getValue() public view returns (uint256) {
        return value;
    }
}