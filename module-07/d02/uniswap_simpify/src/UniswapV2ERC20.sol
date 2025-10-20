// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV2ERC20} from "./interfaces/IUniswapV2ERC20.sol";

import "./libraries/SafeMath.sol";
import {Test, console} from "forge-std/Test.sol";

// Uniswap V2 的 LP Token（流动性凭证 Token）合约实现，其实就是一个特殊的 ERC20 代币，但它额外实现了 permit 功能（EIP-2612），可以通过签名授权，不需要用户先发送一笔 approve 交易。
//      当你往某个交易对池子里添加流动性时，Pair 合约会给你铸造一个 LP Token（代表你在池子里的份额）。
//      这个 LP Token 就是由 UniswapV2ERC20 这个合约实现的。本质上它是一个简化版的 ERC20 合约，带 permit 授权。
/**
 * 这是 Uniswap V2 LP Token 的实现。
 *      - 标准 ERC20 代币。
 *      - 支持 mint / burn，配合 Pair 合约管理流动性份额。
 *      - 支持 permit（EIP-2612），免 approve 节省 Gas。
 *      - transferFrom 优化了无限授权逻辑。
*/
contract UniswapV2ERC20 is IUniswapV2ERC20 {
    using SafeMath for uint256;

    // 这是标准 ERC20 的配置：名字、符号、精度、总供应量。
    string public constant name = "Uniswap V2";
    string public constant symbol = "UNI-V2";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    mapping(address => uint256) public balanceOf;  // 记录每个账户的 LP Token 数量
    mapping(address => mapping(address => uint256)) public allowance;  // 记录授权额度（owner → spender → 可花费额度）

    // EIP-712 / Permit 相关（这是为了实现 签名授权（permit））
    bytes32 public DOMAIN_SEPARATOR;  // 用于区分不同链、不同合约的签名域（构造函数里通过 chainid 和合约地址生成 DOMAIN_SEPARATOR）
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");  // 就是PERMIT_TYPEHASH的hash内容
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;  // 定义了 permit 方法的签名规则
    mapping(address => uint256) public nonces;  // 确保每次签名不同，防止重放攻击

    // 生成离线签名需要的内容
    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    // 流动性变化时调用（比如添加流动性会 mint，移除流动性会 burn）
    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    // 更新授权额度
    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    // 内部转账逻辑
    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    // 和标准 ERC20 一样
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    // transferFrom 里有一个优化：如果 allowance == type(uint256).max（即无限授权），就不会减少授权额度。这样用户只需要授权一次，就能一直用，节省 Gas。
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        // 如果授权额度是 2^256-1（无穷大），就不减少额度，每次都能用
        if (allowance[from][msg.sender] != type(uint256).max) {
            // 如果授权额度不是无穷大，则每次使用多少就要减少多少额度
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);  // sub来自于SafeMath
        }
        _transfer(from, to, value);
        return true;
    }

    // Permit 授权（这里permit 只是提供了一种 更方便的授权方式：用签名而不是链上交易。并没有提供转账操作。需要合约内部调用的时候自己串联起来）
    /**
     * 用户不用先发 approve 交易，而是 离线签一个消息（包括 spender、value、deadline 等）。
     * 任何人都可以调用 permit，只要带上这个签名。
     * 合约内部通过 ecrecover 验证签名，确认是 owner 签的。
     * 成功后，就会执行 _approve 给 spender 授权。
     * 这样用户只需一次 签名 + 一次 swap 交易，而不是先 approve 再 swap，节省了一次链上交易的 Gas。
    */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
        override
    {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "UniswapV2: INVALID_SIGNATURE");

        _approve(owner, spender, value);
    }

}
