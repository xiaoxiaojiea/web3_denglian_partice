// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 引入 ERC20 的基础接口 IERC20 和 EIP-2612 的扩展接口 IERC20Permit
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenBank {
    // 代币对象
    //      代币实例，用于普通的 transferFrom 存款
    IERC20 public token;  
    //      同一个代币，但用的是 IERC20Permit 接口，用于 离线签名授权（permit） 的存款。
    IERC20Permit public permitToken; 

    // 存款余额表，记录每个地址在 TokenBank 里的存款余额。
    mapping(address => uint256) public balances;

    constructor(address _token) {
        // 实例化
        token = IERC20(_token);
        permitToken = IERC20Permit(_token);  // _token必须是 支持 ERC20Permit 的代币，否则 permit() 调用失败。
    }

    // 普通存款函数（需要sender提前授权：token.approve(address(this), amount) ）
    function deposit(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "transfer fail");
        balances[msg.sender] += amount;
    }

    // 用户只需 离线签名一条 permit 消息，再直接调用 permitDeposit，即可一步完成授权 + 存款。
    function permitDeposit(
        uint256 amount,
        uint256 deadline,
        uint8 v, bytes32 r, bytes32 s
    ) external {
        // permit使用代币合约检查签名是否有效，如果有效，它会直接更新内部的 allowance(owner, spender)
        //      owner = msg.sender：代币的持有人
        //      spender = address(this)：被授权的账户
        //      value = amount：授权额度
        //      deadline：签名过期时间（区块时间戳）。
        //      v, r, s：用户之前 链下签名 EIP-712 消息后得到的椭圆曲线签名参数。它们证明了“确实是 msg.sender 签了这条授权消息”。
        permitToken.permit(msg.sender, address(this), amount, deadline, v, r, s);

        // 转移代币
        require(token.transferFrom(msg.sender, address(this), amount), "transfer fail");
        balances[msg.sender] += amount;
    }
}
