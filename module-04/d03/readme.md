


##### 题目1: 为 Bank 合约(module-02/d01) 编写测试。
测试Case 包含：
- 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
- 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
- 检查只有管理员可取款，其他人不可以取款。

解题：
- 创建项目：
    - mkdir c01 
    - cd c01
    - forge init --no-git
    - 生成 Remappings: forge remappings > remappings.txt
    - 在.env中设置自己的参数
    - source .env
    - forge build
    - forge test
- 编写合约代码：src/bank.sol （直接拷贝过去就好了）
- 编写测试：
    - 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确
        - test_deposit_success
    - 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
        - test_top3_user1_success
        - test_top3_user2_success
        - test_top3_user3_success
        - test_top3_user4_success
        - test_top3_user_multi_success
    - 检查只有管理员可取款，其他人不可以取款
        - test_onlyOwner_canWithdraw


测试时出内容：
jie@jie:~/shj_other_ws/学习记录/web3课程02_登链/module-04/d03/c01$ forge test -vvv
[⠊] Compiling...
No files changed, compilation skipped

Ran 7 tests for test/bank.t.sol:CounterTest
[PASS] test_deposit_success() (gas: 98459)
[PASS] test_onlyOwner_canWithdraw() (gas: 95206)
[PASS] test_top3_user1_success() (gas: 101989)
[PASS] test_top3_user2_success() (gas: 177923)
[PASS] test_top3_user3_success() (gas: 255476)
[PASS] test_top3_user4_success() (gas: 291871)
[PASS] test_top3_user_multi_success() (gas: 111655)
Suite result: ok. 7 passed; 0 failed; 0 skipped; finished in 1.56ms (2.46ms CPU time)

Ran 1 test suite in 8.53ms (1.56ms CPU time): 7 tests passed, 0 failed, 0 skipped (7 total tests)






