// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISignatureTransfer} from "permit2/interfaces/ISignatureTransfer.sol";

contract TokenBank {
    // 合约管理的 ERC20 代币地址
    IERC20 public token;

    // Permit2 合约地址，用于执行签名转账
    address public constant PERMIT2_ADDRESS =
        0x5FbDB2315678afecb367f032d93F642f64180aa3;

    // 记录每个用户在 TokenBank 的存款余额
    mapping(address => uint256) public deposits;

    event Deposit(address indexed user, uint256 amount); // 用户存款时触发（便于在链上快速过滤和查询事件）
    event Withdraw(address indexed user, uint256 amount); // 用户取款时触发

    constructor(address _tokenAddress) {
        require(
            _tokenAddress != address(0),
            "TokenBank: token address cannot be zero"
        );
        token = IERC20(_tokenAddress);
    }

    // 普通存款函数（用户必须事先 approve TokenBank 才能使用 transferFrom）
    function deposit(uint256 _amount) external {
        require(
            _amount > 0,
            "TokenBank: deposit amount must be greater than zero"
        );
        require(
            token.balanceOf(msg.sender) >= _amount,
            "TokenBank: insufficient balance"
        );

        // 调用 ERC20 的 transferFrom 从用户钱包转到合约
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "TokenBank: transfer failed");

        // 更新 deposits 映射
        deposits[msg.sender] += _amount;
        // 触发 Deposit 事件
        emit Deposit(msg.sender, _amount);
    }

    // 使用 Permit2 的存款（用户可以通过签名授权代币，无需先调用 approve）
    function depositWithPermit2(
        uint256 _amount, // 转账金额
        uint256 _nonce, // 防重放
        uint256 _deadline, // 签名有效期
        bytes calldata _signature // 用户的签名
    ) external {
        require(
            _amount > 0,
            "TokenBank: deposit amount must be greater than zero"
        );
        require(
            token.balanceOf(msg.sender) >= _amount,
            "TokenBank: insufficient balance"
        );

        // ========================= 创建 Permit2 所需的数据结构
        //      permit：定义用户允许的代币和数量
        ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer
            .PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: address(token),
                    amount: _amount
                }),
                nonce: _nonce,
                deadline: _deadline
            });

        //      transferDetails：实际转账信息
        ISignatureTransfer.SignatureTransferDetails
            memory transferDetails = ISignatureTransfer
                .SignatureTransferDetails({
                    to: address(this),
                    requestedAmount: _amount
                });

        // ========================= 调用 Permit2 的 permitTransferFrom 执行代币转账。
        ISignatureTransfer(PERMIT2_ADDRESS).permitTransferFrom(
            permit,
            transferDetails,
            msg.sender,
            _signature
        );

        // 最后更新 deposits 并触发事件
        deposits[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    // 取款函数
    function withdraw(uint256 _amount) external {
        require(
            _amount > 0,
            "TokenBank: withdraw amount must be greater than zero"
        );
        require(
            deposits[msg.sender] >= _amount,
            "TokenBank: insufficient deposit"
        );

        deposits[msg.sender] -= _amount;
        bool success = token.transfer(msg.sender, _amount); // 调用 ERC20 transfer 将代币转回用户
        require(success, "TokenBank: transfer failed");

        emit Withdraw(msg.sender, _amount);
    }

    // 查询余额
    function balanceOf(address _user) external view returns (uint256) {
        return deposits[_user];
    }
}
