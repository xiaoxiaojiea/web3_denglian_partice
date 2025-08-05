
编写一个 Bank 合约，实现功能：
- 可以通过 Metamask 等钱包直接给 Bank 合约地址存款
- 在 Bank 合约记录每个地址的存款金额
- 编写 withdraw() 方法，仅管理员可以通过该方法提取资金。
- 用数组记录存款金额的前 3 名用户

receive/fallfack函数
- 在 Solidity 中，合约可以接收以太币，有两种特殊函数（只有含有了这两种函数，该合约才被允许接受ETH）：
    - receive() 函数：当收到 纯以太（不带 calldata） 的时候调用。
    - fallback() 函数：合约兜底处理逻辑，当调用的函数 不存在 或者 calldata 非空但没有匹配函数时，会调用 fallback。
- 调用方式
    - send / transfer -> 触发 receive()
    - call 携带数据 -> 若无匹配函数 -> 触发 fallback()

payable 使用、及从合约里面转出 ETH
- 普通 address 不能直接转账，必须先转换为 address payable。比如：payable(msg.sender).transfer(1 ether)
- 从合约转出 ETH 的三种方法：
    - transfer：推荐用于简单用途。
        - payable(msg.sender).transfer(1 ether);
        - 固定使用gas：2300（不能调用接收方的复杂逻辑，也就是说接收方的receive()有特殊操作，则transfer转张会失败）
        - 会 revert（回滚）如果失败
        - 安全性高，适用于大多数情况
    - send：一般不推荐使用。
        - bool sent = payable(msg.sender).send(1 ether);
        - require(sent, "Send failed");
        - 同样 gas 限制为 2300，返回 bool 而不是自动回滚（所以要自己写代码判定），容易忘记检查返回值 ⇒ 容易出漏洞
    - call：推荐用于高级用途
        - (bool success, ) = payable(msg.sender).call{value: 1 ether}("");
        - require(success, "Transfer failed");
        - 推荐的现代方式
        - 可自定义 gas（默认几乎无限）
        - 可触发接收方复杂逻辑（如 fallback）
        - 适用于复杂合约或升级场景



