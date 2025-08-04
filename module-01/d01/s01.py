import hashlib
import time

"""
原理解析：
- POW：工作量证明，是区块链中的核心挖矿原理，他的目的就是人为的产生挖矿难度，让挖矿工作能够持续进行下去。
    - 核心思想：参与者（通常称为“矿工”）必须完成一个计算上很难但验证很容易的问题，这个过程就叫“挖矿”。
    - 例子：对一个区块头信息加上一个随机数（nonce）进行哈希，使结果的哈希值小于某个目标值（通常是以一定数量的前导0开头）。
        成功者可以将新的区块添加到区块链中并获得奖励（如比特币）。这个过程只能不断尝试随机数来找到符合条件的值，计算量巨大，但找到之后别人可以一眼验证。

- 代码模拟：
    - 问题：在这里认为区块hash是人为指定的一串字符串（“用户标识符”），然后目的是找到一个nonce，使得 hash(用户标识符 + nonce) 
        满足一个比较苛刻的条件（比如开头由连续的多少个0组成），前导零越多，目标值越小，难度越高（因为哈希值均匀分布，概率更低）。
    - 这里有一个很重要的前提：这个过程只能不断尝试随机数来找到符合条件的值。
    - 代码实现如下：
"""

def pow_example(nickname, leading_zeros):
    print(f"\n开始寻找 {leading_zeros} 个前导零的哈希值...")
    start_time = time.time()
    nonce = 0

    # 前导指定数量的0形成的字符串
    target = '0' * leading_zeros
    
    while True:
        # 相同的字符串input_data得到的hash_result是同一个 
        input_data = nickname + str(nonce)

        # 计算hash
        hash_result = hashlib.sha256(input_data.encode()).hexdigest()
        
        # 判断hash是否由指定数量的0开头
        if hash_result.startswith(target):
            end_time = time.time()
            elapsed = end_time - start_time
            print(f"找到符合条件的哈希值！")
            print(f"输入内容: {input_data}")
            print(f"哈希值: {hash_result}")
            print(f"耗时: {elapsed:.4f} 秒")
            print(f"尝试次数: {nonce + 1}")
            return
        
        nonce += 1
        # 每100万次打印一次进度（可选）
        if nonce % 1000000 == 0:
            print(f"已尝试 {nonce} 次...", end='\r')

# 用户输入昵称
nickname = "0x8959404600a476dd57f2ca080fa4a69fcee73797"

# 寻找4个前导零的哈希值
pow_example(nickname, 4)

# 寻找5个前导零的哈希值
pow_example(nickname, 5)

"""

开始寻找 4 个前导零的哈希值...
找到符合条件的哈希值！
输入内容: 0x8959404600a476dd57f2ca080fa4a69fcee73797148241
哈希值: 0000e62ba3418bf8678b32ccea8397263393e5de229548de069461ee7141a586
耗时: 0.0853 秒
尝试次数: 148242

开始寻找 5 个前导零的哈希值...
找到符合条件的哈希值！
输入内容: 0x8959404600a476dd57f2ca080fa4a69fcee737973020437
哈希值: 0000045be0015b0553237e2cb4331630c7496906b29fac87b09fdf0144ab2b71
耗时: 1.7105 秒
尝试次数: 3020438

"""