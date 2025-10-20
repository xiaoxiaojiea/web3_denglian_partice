// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol"; // 接口，声明了事件和核心方法
import {UniswapV2ERC20} from "./UniswapV2ERC20.sol"; // 实现 LP Token（流动性凭证）的 ERC20 功能

import "./libraries/UQ112x112.sol"; // 用于固定点数的价格计算
import "./libraries/Math.sol"; // 常用数学操作，如平方根

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Callee.sol";

import {Test, console} from "forge-std/Test.sol"; // 方便调试

// Uniswap V2 的核心 Pair 合约实现，负责管理单个交易对的流动性、储备、交换、铸币/销币等逻辑。
/**
 *
 *
 */
contract UniswapV2Pair is UniswapV2ERC20, IUniswapV2Pair {
    using UQ112x112 for uint224; // 用于固定点数的价格计算

    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;  // MINIMUM_LIQUIDITY 永久锁定到 address(0)，防止池子被清空
    bytes4 private constant SELECTOR =
        bytes4(keccak256(bytes("transfer(address,uint256)"))); // 转账函数选择器

    address public factory; // 创建此 Pair 的工厂合约地址
    address public token0; // 交易对的两个代币地址
    address public token1;

    uint112 private reserve0; // 池子当前的储备量（核心概念）
    uint112 private reserve1;
    uint32 private blockTimestampLast; // 上次储备更新的区块时间戳

    uint256 public price0CumulativeLast; // 累积价格，用于链上价格 Oracle
    uint256 public price1CumulativeLast;

    uint256 public kLast; // 最近一次流动性事件后的 reserve0 * reserve1，用于计算手续费

    uint256 private unlocked = 1; // lock 修饰符：防重入锁

    // 防止重入攻击：保护 mint、burn、swap 等函数避免重入攻击
    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0; // 先把 unlocked 设为 0，函数执行完再恢复为 1
        _;
        unlocked = 1;
    }

    // 返回当前储备量和上次更新时间
    /**
     * 储备量用于：
     *      - 计算兑换比例
     *      - 检查流动性是否足够
     *      - 更新累积价格
     */
    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // 安全转账代币（支持非标准 ERC20（没有返回值的）代币）
    function _safeTransfer(address token, address to, uint256 value) private {
        // 使用token的底层call方法来转账
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(SELECTOR, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "UniswapV2: TRANSFER_FAILED"
        );
    }

    // factory对Pair进行管理，所以这个合约只能factory调用
    constructor() {
        factory = msg.sender;
    }

    // 只能被工厂调用，设置交易对代币地址
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "UniswapV2: FORBIDDEN"); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    //
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 _reserve0,
        uint112 _reserve1
    ) private {
        require(
            // balance0 <= uint112(-1) && balance1 <= uint112(-1),
            // 使用 uint112 的最大值来替代 -1
            balance0 <= type(uint112).max && balance1 <= type(uint112).max,
            "UniswapV2: OVERFLOW"
        );
        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            // _reserve1 * 2 ** 112 / _reserve0 * timeElapsed
            // 在 OraclePrice 使用，在本合约中只记录未使用
            // https://github.com/Uniswap/v2-periphery/blob/master/contracts/examples/ExampleOracleSimple.sol
            price0CumulativeLast +=
                uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // Uniswap V2 的核心手续费函数，它不是用户调用的，而是 在 mint 或 burn 时内部调用，目的是 按池子增值给协议收取手续费
    /**
     * 总结：（_mintFee = “Uniswap 的自动协议手续费收割器”）
     *      - _mintFee 只在 流动性增加/减少时调用
     *      - 目的是 为协议收取手续费
     *      - 逻辑核心：
     *          - 计算池子增值量 √(reserve0*reserve1) - √(kLast)
     *          - 按比例 mint LP Token 给 feeTo
     *      - 如果未开启手续费，则 _kLast 重置为 0，不再累计。
     *      - 不会影响用户流动性，只会在 mint/burn 时自动扣除少量 LP Token 给协议。
    */
    function _mintFee(
        uint112 _reserve0,
        uint112 _reserve1
    ) private returns (bool feeOn) {
        // _reserve0 / _reserve1：当前池子储备量。
        // returns feeOn：返回是否开启了手续费收取

        // 检查手续费收款地址（这里的设计允许 协议可以开关手续费（例如 Uniswap v2 默认在前期不开，后来可开启））
        address feeTo = IUniswapV2Factory(factory).feeTo();  // 从工厂合约读取 feeTo 地址
        feeOn = feeTo != address(0);  // 如果不为 0x0 → 开启手续费，否则 → 不收手续费

        // _kLast 是上一次流动性事件后的储备乘积 reserve0 * reserve1
        uint256 _kLast = kLast; // _kLast 用于计算这次池子增值

        if (feeOn) {  // 开了手续费
            if (_kLast != 0) {  // 计算新增流动性带来的手续费

                // 计算平方根的功能通常需要自定义实现或使用库函数
                uint256 rootK = Math.sqrt(_reserve0 * _reserve1);  // rootK = 当前储备乘积平方根
                uint256 rootKLast = Math.sqrt(_kLast);  // rootKLast = 上一次储备乘积平方根

                // 差值 rootK - rootKLast → 本次流动性增值量
                if (rootK > rootKLast) {  // 计算给协议收取的 LP Token 数量（0.05% 的手续费对应的比例）
                    // 公式来源于 Uniswap V2 的设计

                    // 计算分子 s1 * (根号下k2 - 根号下k1)
                    uint256 numerator = totalSupply * (rootK - rootKLast);  // 分子：totalSupply * 增值量

                    // 计算分母 5 * 根号下k2 + 根号下k1
                    uint256 denominator = rootK * 5 + rootKLast;  // 分母：5 * rootK + rootKLast

                    // 计算流动性 Sm = 分子 / 分母
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);  // mint 给手续费接收者
                }
            }
        } else if (_kLast != 0) {  // 重置 kLast = 0，表示手续费不再累计
            kLast = 0;
        }

    }

    // 用户调用这个函数，把 token0 和 token1 添加到池子中，获得 LP Token
    /**
     * 总结 mint 流程：
     *      - 读取池子储备量
     *      - 计算用户实际添加的 token 数量
     *      - 可选：铸造手续费给 feeTo
     *      - 根据比例计算 LP Token 数量
     *      - mint LP Token 给用户
     *      - 更新储备量和累积价格
     *      - 更新 kLast（手续费）
     *      - 发出 Mint 事件
     * 这个函数体现了 Uniswap 的恒定乘积逻辑 + LP Token 分配 + 手续费机制 的核心思想
    */
    function mint(address to) external lock returns (uint256 liquidity) {
        /**
         * to：接收 LP Token 的地址
         * lock：防重入锁，确保函数执行期间不会被重入攻击干扰
         * liquidity：本次 mint 铸造给用户的 LP Token 数量
         */

        // 调用 getReserves 返回池子当前的储备量（也就是 添加流动性前池子里的代币数量）
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); 

        // 读取合约里 实际持有的 token0 和 token1 的余额（这可能比储备量多，因为用户刚刚转入了一部分 token）
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // 计算用户本次实际添加到池子的 token 数量（本次新增的流动性量，这两个数用于计算应该 mint 多少 LP Token）
        uint256 amount0 = balance0 - _reserve0;  // balance* - _reserve* 就是 本次新增的流动性量
        uint256 amount1 = balance1 - _reserve1;

        // 铸造手续费 LP Token
        /**
         * 检查工厂是否开启手续费收取，如果开启：
         *      - 根据公式 sqrt(k) - sqrt(kLast) 计算新增流动性增量。
         *      - 铸造给手续费接收者。
         * feeOn 标记是否开启手续费
        */
        bool feeOn = _mintFee(_reserve0, _reserve1);

        // 获取当前总供应量（当前LP Token 的总供应量）
        uint256 _totalSupply = totalSupply;  // 保存到局部变量 _totalSupply，因为 _mintFee 可能修改了 totalSupply

        // 计算本次 mint 的 LP Token 数量
        if (_totalSupply == 0) {  // 第一个流动性提供者：liquidity = sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY
            // MINIMUM_LIQUIDITY 永久锁定到 address(0)
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;

            // 防止池子被清空 保证池子永远不会被完全清空，从而避免除零错误和恒定乘积公式失效。
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {  // 已有流动性时：liquidity = min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1)
            // min 保证不会因为两种 token 比例不一致而导致超额 mint（确保 mint 的 LP Token 按现有池子比例分配）
            liquidity = Math.min(
                (amount0 * _totalSupply) / _reserve0,
                (amount1 * _totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED");  // 防止用户添加过少流动性导致计算出的 LP Token 为 0

        // 铸造 LP Token 给用户
        _mint(to, liquidity);

        // 更新储备量
        /**
         * - 更新 reserve0 和 reserve1
         * - 更新 blockTimestampLast
         * - 更新累积价格（price0CumulativeLast / price1CumulativeLast）
         * - 发出 Sync 事件
        */
        _update(balance0, balance1, _reserve0, _reserve1);

        // 更新 kLast（如果开启手续费）
        if (feeOn) kLast = reserve0 * reserve1; // _kLast = 上次流动性事件的“池子价值基准”，用它来算增值给协议收手续费。

        // 谁为这两个token各添加了多少代币
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(
        address to
    ) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(
            amount0 > 0 && amount1 > 0,
            "UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED"
        );
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = reserve0 * reserve1; // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(
            amount0Out > 0 || amount1Out > 0,
            "UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves(); // gas savings
        require(
            amount0Out < _reserve0 && amount1Out < _reserve1,
            "UniswapV2: INSUFFICIENT_LIQUIDITY"
        );
        uint256 balance0;
        uint256 balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "UniswapV2: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) {
                // 闪电贷
                IUniswapV2Callee(to).uniswapV2Call(
                    msg.sender,
                    amount0Out,
                    amount1Out,
                    data
                );
            }
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out
            ? balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out
            ? balance1 - (_reserve1 - amount1Out)
            : 0;
        require(
            amount0In > 0 || amount1In > 0,
            "UniswapV2: INSUFFICIENT_INPUT_AMOUNT"
        );
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint256 balance0Adjusted = balance0 * 1000 - amount0In * 3;
            uint256 balance1Adjusted = balance1 * 1000 - amount1In * 3;
            uint256 requiredValue = uint256(reserve0) *
                uint256(reserve1) *
                (1000 ** 2);
            require(
                balance0Adjusted * balance1Adjusted >= requiredValue,
                "UniswapV2: K"
            );
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // 把合约里多余的代币转给 to，保持储备与实际余额一致
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 currentBalance = IERC20(_token0).balanceOf(address(this));

        _safeTransfer(_token0, to, currentBalance - reserve0);
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)) - reserve1
        );
    }

    // 更新储备量与实际代币余额同步
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}
