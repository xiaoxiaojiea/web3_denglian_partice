// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Bank is Ownable, AutomationCompatibleInterface {
    // AutomationCompatibleInterface：接口要求实现 checkUpkeep 和 performUpkeep，用于 Chainlink 自动化任务（定时/条件触发）。

    mapping(address => uint256) public balances;

    uint256 public threshold;

    event Deposited(address indexed user, uint256 amount);
    event AutoTransfer(address indexed owner, uint256 amount);

    constructor(uint256 _threshold, address _owner) Ownable(_owner) {
        threshold = _threshold;
    }

    function deposit() external payable {
        require(msg.value > 0, "Must send ETH");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function setThreshold(uint256 _threshold) external onlyOwner {
        threshold = _threshold;
    }

    // -------- Chainlink Automation 接口 --------
    // checkUpkeep：Chainlink 节点会定期调用 checkUpkeep
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // upkeepNeeded：如果合约余额大于或等于阈值，则返回 true，表示需要执行自动任务。
        upkeepNeeded = address(this).balance >= threshold;
        // performData：可传递给 performUpkeep 的数据，这里传递 owner 地址。
        performData = abi.encode(owner()); // 传递给 performUpkeep
    }

    // performUpkeep：Chainlink 节点检测到 upkeepNeeded == true 时会调用
    function performUpkeep(bytes calldata performData) external override {
        // performData：checkUpkeep中传递的数据，可以直接从中解析出来需要的数据

        address recipient = abi.decode(performData, (address));  // 取出 performData 中的收款人
        uint256 totalBalance = address(this).balance;

        // 检查合约余额是否达到阈值
        if (totalBalance >= threshold) {
            // 转账 合约总余额的一半 给 owner
            uint256 half = totalBalance / 2;
            (bool sent, ) = recipient.call{value: half}("");
            require(sent, "Transfer failed");

            emit AutoTransfer(recipient, half);
        }
    }

}
