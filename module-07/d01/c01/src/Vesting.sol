// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 代币线性解锁合约，采用悬崖式释放模式。
/**
 * 题目：
 *      - Cliff 12个月（锁仓12个月）
 *      - 接下来的 24 个月，从 第 13 个月起开始每月解锁 1/24 的 ERC20
 *      - release方法可以让受益人提取解锁的代币
 *      - 部署时开始计算 Cliff ，并转入 100 万 ERC20 资产
*/

contract Vesting is Ownable {
    // 状态变量
    IERC20 public immutable token;  // 要解锁的ERC20代币
    address public immutable beneficiary;  // 受益人地址（唯一可提取代币的地址）
    uint256 public immutable start;  // 解锁开始时间戳
    uint256 public immutable cliff;  // 悬崖期结束时间（12个月后）
    uint256 public immutable vestingEnd;  // 完全解锁时间（悬崖期+24个月）
    uint256 public released;  // 已释放的代币数量

    // 常量定义
    uint256 private constant MONTH = 30 days;  // 每月按30天计算
    uint256 private constant CLIFF_MONTHS = 12;  // 12个月悬崖期
    uint256 private constant VEST_MONTHS = 24;  // 24个月释放期

    event Released(address indexed beneficiary, uint256 amount);

    // 构造函数：初始化合约，设置代币和受益人，计算关键时间点
    constructor(IERC20 _token, address _beneficiary) Ownable(msg.sender) {
        require(address(_token) != address(0), "token zero");
        require(_beneficiary != address(0), "beneficiary zero");
        
        token = _token;  // 设置代币
        beneficiary = _beneficiary;  // 设置受益人

        // 计算关键时间点
        start = block.timestamp;  // 解锁开始时间戳
        cliff = start + (CLIFF_MONTHS * MONTH);  // 悬崖期结束时间（12个月后）
        vestingEnd = cliff + (VEST_MONTHS * MONTH);  // 完全解锁时间（悬崖期+24个月）
    }

    // 已解锁金额计算
    function vestedAmount() public view returns (uint256) {
        uint256 totalAllocated = token.balanceOf(address(this)) + released;
        
        // 悬崖期内，返回0
        if (block.timestamp < cliff) {
            return 0;
        }
        
        // 已完全解锁，返回总分配量
        if (block.timestamp >= vestingEnd) {
            return totalAllocated;
        }
        
        // 中间阶段：按月份线性解锁
        /**
         * 示例计算：假设总分配1000个代币，第18个月时：
         *      monthsVested = (18 - 12) = 6个月
         *      vestedAmount = 1000 * 6 / 24 = 250个代币
        */
        //      计算从悬崖期开始经过的时间
        uint256 timeSinceCliff = block.timestamp - cliff;
        
        //      计算已解锁的月份数（从0开始计数）
        uint256 monthsVested = timeSinceCliff / MONTH;
        
        //      确保不超过总释放月份数
        if (monthsVested > VEST_MONTHS) {
            monthsVested = VEST_MONTHS;
        }
        
        return (totalAllocated * monthsVested) / VEST_MONTHS;
    }

    // 可提取金额计算（计算当前可提取的代币数量：已解锁金额 - 已释放金额）
    function releasableAmount() public view returns (uint256) {
        uint256 vested = vestedAmount();
        return vested > released ? vested - released : 0;
    }

    // 提取功能 
    function release() external {
        // 只能由受益人调用
        require(msg.sender == beneficiary, "only beneficiary");
        
        // 检查有可提取的代币
        uint256 amount = releasableAmount();
        require(amount > 0, "no tokens to release");
        
        // 转账并更新已释放数量
        released += amount;
        require(token.transfer(beneficiary, amount), "transfer failed");
        
        emit Released(beneficiary, amount);
    }
}
