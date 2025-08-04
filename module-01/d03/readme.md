
## 基础内容

- 概念：
    - **Gas**：每一项操作消耗的单位计算资源。
        - 每一个操作（如加法、转账、存储）在以太坊虚拟机中都有一个固定的“计算资源成本”，单位就是 Gas。
    - **Gas Limit**：用户愿意为一次交易最多消耗的 Gas 上限。
    - **Gas Used**：实际执行时消耗的 Gas
        - 比如：转账的操作就用掉了 21,000 个 Gas
    - **Gas Price**：用户愿意为每单位 Gas 支付的 ETH（或 Gwei）价格
        - 每个Gas的价格，比如：50 Gwei（1 Gwei = 10⁻⁹ ETH）
    - **Tx Fee (手续费)**：Gas Used × Gas Price，即实际交易成本
        - Tx Fee = 21,000 × 50 Gwei = 1,050,000 Gwei = 0.00105 ETH

- Gas计算的基本规则：以太坊虚拟机（EVM）中，每个操作码（Opcode）都对应一个固定的 Gas 消耗。
    - ADD 加法：3个Gas
    - MUL 乘法：5个Gas
    - SSTORE 写入存储：20,000个Gas（首次写入），5,000个Gas（修改）
    - SLOAD 读取存储：800
    - 调用合约：~700个Gas + 动态计算
    - 转账 (transfer)：21,000个Gas

- Gas的计算公式：**注意Fee限制的是Gas Price，Gas Limit限制的是Gas Used**
    - 简化版本：Tx Fee = Gas Used × (Base Fee + Priority Fee)
        - Gas Used：实际使用的Gas，动态计算用户无法控制，只能时即用Gas Limit限制而已。
        - Base Fee：系统自动调整的最小费用（销毁），一般系统默认的，用户无法控制。
        - Priority Fee：用户主动加的小费（奖励矿工），用户可以控制。
    - 完整版本：Tx Fee = Gas Used × (min(Base Fee, Max Fee - Priority Fee) + Priority Fee)
        - Max Fee：限制了(Base Fee + Priority Fee)的总和，也就是说用户愿意支付的Fee最大值。

### 题目1：
在以太坊上，用户发起一笔交易 设置了GasLimit 为 10000, Max Fee 为 10 GWei, Max priority fee 为 1 GWei ， 为此用户应该在钱包账号里多少 GWei 的余额？
- Tx Fee = Gas Used × (min(Base Fee, Max Fee - Priority Fee) + Priority Fee)
    - Tx Fee = 10000 × 10 Gwei = 100000Gwei

### 题目2：
在以太坊上，用户发起一笔交易 设置了 GasLimit 为 10000, Max Fee 为 10 GWei, Max priority Fee 为 1 GWei，在打包时，Base Fee 为 5 GWei, 实际消耗的Gas为 5000， 那么矿工（验证者）拿到的手续费是多少 GWei ?
- Tx Fee = Gas Used × (min(Base Fee, Max Fee - Priority Fee) + Priority Fee)
    - 5000 x 1 GWei = 5000 GWei

### 题目3：
在以太坊上，用户发起一笔交易 设置了 GasLimit 为 10000, Max Fee 为 10 GWei, Max priority Fee 为 1 GWei，在打包时，Base Fee 为 5 GWei, 实际消耗的Gas为 5000， 那么用户需要支付的的手续费是多少 GWei ?
- Tx Fee = Gas Used × (min(Base Fee, Max Fee - Priority Fee) + Priority Fee)
    - 5000 x ( 5 GWei + 1 GWei) = 30000 GWei

### 题目4：
在以太坊上，用户发起一笔交易 设置了 GasLimit 为 10000, Max Fee 为 10 GWei, Max priority Fee 为 1 GWei，在打包时，Base Fee 为 5 GWei, 实际消耗的 Gas 为 5000， 那么燃烧掉的 Eth 数量是多少 GWei ?
- Tx Fee = Gas Used × (min(Base Fee, Max Fee - Priority Fee) + Priority Fee)
    - 5000 x 5 GWei = 25000 GWei
