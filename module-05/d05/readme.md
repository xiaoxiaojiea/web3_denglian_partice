
### 基础知识

在上一节体验了第三方提供的多签钱包功能之后，我们可以自己使用合约写一个多签合约，功能大致相同，唯一不同的就是人家提供界面端（通过扫链拿到的状态）

##### 题目#1
实现⼀个简单的多签合约钱包，合约包含的功能：
- 创建多签钱包时，确定所有的多签持有⼈和签名门槛
- 多签持有⼈可提交提案
- 其他多签⼈确认提案（使⽤交易的⽅式确认即可）
- 达到多签⻔槛、任何⼈都可以执⾏交易


使用foundry操作多签智能合约
- mkdir c01 && cd c01/
- forge init --no-git
- forge remappings > remappings.txt
- 本地测试环境准备
    - 在.env中设置自己的参数
    - source .env
- 编写MultiSigWallet.sol合约内容
- 编写MultiSigWallet.t.sol合约测试内容
- forge build
- forge test 即可看到测试输出
    ```
    jie@jie:~/shj_other_ws/学习记录/web3课程02_登链/module-05/d05/c01$ forge test
    [⠊] Compiling...
    No files changed, compilation skipped

    Ran 8 tests for test/MultiSigWallet.t.sol:MultiSigWalletTest
    [PASS] testConfirmTransaction() (gas: 230618)
    [PASS] testContractCall() (gas: 363243)
    [PASS] testDeployment() (gas: 33841)
    [PASS] testExecuteTransaction() (gas: 230089)
    [PASS] testNonOwnerCannotSubmit() (gas: 17742)
    [PASS] testReceiveEther() (gas: 20576)
    [PASS] testRevokeConfirmation() (gas: 125025)
    [PASS] testSubmitTransaction() (gas: 141649)
    Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 1.95ms (2.66ms CPU time)

    Ran 1 test suite in 8.06ms (1.95ms CPU time): 8 tests passed, 0 failed, 0 skipped (8 total tests)
    ```




