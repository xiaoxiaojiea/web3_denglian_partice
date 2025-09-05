// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISignatureTransfer} from "permit2/interfaces/ISignatureTransfer.sol";

contract TokenBank {
    IERC20 public token;

    address public constant PERMIT2_ADDRESS =
        0x000000000022D473030F116dDEE9F6B43aC78BA3;

    mapping(address => uint256) public deposits;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "TokenBank: token address cannot be zero");
        token = IERC20(_tokenAddress);
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "TokenBank: deposit amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= _amount, "TokenBank: insufficient balance");

        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "TokenBank: transfer failed");

        deposits[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function depositWithPermit2(
        uint256 _amount,
        uint256 _nonce,
        uint256 _deadline,
        bytes calldata _signature
    ) external {
        require(_amount > 0, "TokenBank: deposit amount must be greater than zero");
        require(token.balanceOf(msg.sender) >= _amount, "TokenBank: insufficient balance");

        ISignatureTransfer.PermitTransferFrom memory permit =
            ISignatureTransfer.PermitTransferFrom({
                permitted: ISignatureTransfer.TokenPermissions({
                    token: address(token),
                    amount: _amount
                }),
                nonce: _nonce,
                deadline: _deadline
            });

        ISignatureTransfer.SignatureTransferDetails memory transferDetails =
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: _amount
            });

        ISignatureTransfer(PERMIT2_ADDRESS).permitTransferFrom(
            permit,
            transferDetails,
            msg.sender,
            _signature
        );

        deposits[msg.sender] += _amount;
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "TokenBank: withdraw amount must be greater than zero");
        require(deposits[msg.sender] >= _amount, "TokenBank: insufficient deposit");

        deposits[msg.sender] -= _amount;
        bool success = token.transfer(msg.sender, _amount);
        require(success, "TokenBank: transfer failed");

        emit Withdraw(msg.sender, _amount);
    }

    function balanceOf(address _user) external view returns (uint256) {
        return deposits[_user];
    }
}
