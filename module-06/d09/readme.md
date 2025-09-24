

### 基础知识



##### 安全挑战：Hack Vault
- Fork 代码库：https://github.com/OpenSpace100/openspace_ctf
    - 阅读代码  Vault.sol 及测试用例，在测试用例中 testExploit 函数添加一些代码，设法取出预先部署的 Vault 合约内的所有资金。
    - 以便运行 forge test 可以通过所有测试。
    - 可以在 Vault.t.sol 中添加代码，或加入新合约，但不要修改已有代码。

**题目解答**
- 环境准备
    - 直接下载 openspace_ctf-main.zip 然后解压出来修改为 openspace_ctf 文件夹即可；
    - 从别的文件夹中拷贝 forge-std 到lib中
    - forge remappings > remappings.txt
    - forge build 
    - 补全代码
    - forge test -vvvv

- 代码解读：
    - 漏洞解读：
        - 代理合约 Vault 的 fallback() 不受限地 delegatecall 到 VaultLogic，而 delegatecall 会在 Vault 的 storage 上执行 VaultLogic 的代码；
        - 由于 VaultLogic 的 password 与 Vault 的 logic 地址恰好映射到同一 storage slot，攻击者可以构造可以通过校验的 password（等于 bytes32(uint160(address(logic)))），以 delegatecall 调用 changeOwner 把 Vault.owner 劫持为攻击者，再打开提现并配合其它手段把钱取走。
        - 然后直接通过slot修改deposites数据（**真实链上做不到**）
            - vm.store 是 测试 cheatcode，只在 Foundry 的本地/测试环境可用，链上没有等价操作。在真实主网或测试网，外部无法任意写任意合约 storage slot（只能通过合约公开的函数、delegatecall、或合约被升级/自毁/自有写操作来改变 storage）。
            - 因此用 vm.store 写 slot 仅用于测试/演示/复现场景，并非现实攻击的通用路径。
            - 若要在链上实现类似效果，攻击者须要：
                -利用合约本身的逻辑（比如 delegatecall 到恶意实现、或合约允许升级 implementation），或者
                - 利用合约有写任意 slot 的函数（非常罕见且危险），或
                - 通过重入、类型混淆等边缘漏洞间接覆盖目标 slot。
        - withdraw() 本身的实现（checks/effects/interactions 错误）放大了风险。

