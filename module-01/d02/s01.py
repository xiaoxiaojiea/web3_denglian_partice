import hashlib
import json
import time
from typing import List, Dict, Any
import random
import string

"""
区块链的前置知识：
- 区块结构（Block）
    - index: 区块的高度或编号
    - timestamp: 区块创建时间
    - transactions: 交易记录列表
    - proof: 工作量证明所得的值（nonce）
    - previous_hash: 上一个区块的哈希，确保链的连接
- 链式结构（Chain）
    - 每个区块都记录前一个区块的哈希值（previous_hash），从而串成链。
    - 如果任何一个区块被篡改，其哈希变化会导致整条链无效，确保数据不可篡改。
- 哈希函数
    - 使用如 SHA-256 的加密哈希函数将区块内容压缩成定长的字符串。
- 工作量证明POW
    - 找一个nonce值，使得整个区块内容计算出的哈希值满足“以n个0开头”的条件。
- 区块链中的签名：
    - 非对称加密的基础
        - 私钥（Private Key）：自己保管，不对外公开
        - 公钥（Public Key）：可以公开分享，别人用来验证你签名的合法性
    - 签名不是加密：在区块链中使用非对称加密的主要用途不是加密数据，而是用于签名和验证签名。
        - 加密：公钥加密，私钥解密
        - 签名：私钥签名，公钥验证
        - tips：公钥加密之后的密文只能由私钥解开，但是区块链中却无需解开密文只需要验证即可。
    - 签名：私钥签名后内容可以经过公钥验证该内容是不是由某个私钥签名的
        - 私钥签名后的内容，公钥是如何验证的：验证算法会将原始数据和签名一起输入，使用公钥通过特定数学公式判断签名是否合法（是否由当前公钥对应的私钥签名的）。
        - 签名过程（以交易为例）
            - 用户生成密钥对：私钥 + 公钥
            - 构造交易内容：如 from A to B amount 10
            - 用私钥对交易内容的哈希进行签名
            - 将 “交易内容” 和 “签名” 一起广播出去
            - 其他节点用公钥验证 “交易内容” 和 “签名” 是否有效。
        - tips：用户会将 “交易内容” 与 “签名” 一起发送到网络中，以供大家验证；

- 代码模拟：
    - 按照上述思路，代码实现思路如下：
        - 实例化区块链（会拿到创始区块）
        - 向当前区块中添加一些交易
        - 然后拿着当前区块的所有交易去解算nonce
        - 然后将解算的区块添加到chain后面
        - 验证整条chain是否有效

"""

class MinimalBlockchain:
    def __init__(self):
        # 区块链list
        self.chain = []

        # 当前出现的交易list
        self.current_transactions = []

        # 创建创世区块
        self.create_genesis_block()

    def create_genesis_block(self):
        """创建创世区块"""
        genesis_block = {
            'index': 1,  # 区块高度
            'timestamp': time.time(),  # 时间戳
            'transactions': ["创始区块by SHJ。"],  # [交易列表]
            'proof': 100,  # POW证明，创世区块的proof可以是任意值（其实就是解算拿到的nonce）
            'previous_hash': '1' * 64  # 前一区块哈希，模拟64位哈希
        }
        self.chain.append(genesis_block)
    
    def new_transaction(self, sender, recipient, amount):
        """添加新交易到当前交易列表"""
        self.current_transactions.append({
            'sender': sender,
            'recipient': recipient,
            'amount': amount
        })

    def mine(self, miner_address):
        """挖矿产生新区块"""

        # ====================================== 生成矿工奖励交易(就是多加一笔 奖励给矿工的 交易)
        self.new_transaction(
            sender="0",  # 0表示系统奖励
            recipient=miner_address,  # 给矿工的转账
            amount=0.1  # 假设奖励0.1个币
        )

        # ====================================== 拿到最后一个区块来进行挖矿
        last_block = self.chain[-1]  # 最后一个区块
        last_proof = last_block['proof']  # 拿到上一个区块的pow nonce
        last_hash = last_block['previous_hash']  # 拿到上一个区块的hash
        # 执行POW挖矿
        proof = self.proof_of_work(last_hash, last_proof)  

        # 创建新区块
        block = {
            'index': last_block['index'] + 1,  # 区块序号
            'timestamp': time.time(),  # 产生区块时间戳
            'transactions': self.current_transactions,  # 当前区块中包含的交易
            'proof': proof,  # 当前区块的工作量
            'previous_hash': self.hash(last_block)  # 上一个区块
        }

        # 重置当前交易列表
        self.current_transactions = []
        self.chain.append(block)

        return block

    # 简单的POW算法（str = last_hash + last_proof + nonce）
    def proof_of_work(self, last_hash, last_proof):
        """简单的工作量证明算法:
         - 查找一个 p' 使得 hash(pp') 以5个0开头
         - p 是上一个块的 proof, p' 是新的 proof
        """

        proof = 0
        while not self.valid_proof(last_hash, last_proof, proof):
            proof += 1
        return proof

    def valid_proof(self, last_hash, last_proof, proof):
        """验证proof是否满足条件: hash(last_proof, proof)以5个0开头"""
        
        guess = last_hash + str(last_proof) + str(proof)
        guess_hash = hashlib.sha256(guess.encode()).hexdigest()

        return guess_hash.startswith('00000')


    def validate_chain(self):
        """验证区块链是否有效"""
        for i in range(1, len(self.chain)):
            current_block = self.chain[i]
            previous_block = self.chain[i - 1]

            # 检查hash是否正确连接
            if current_block['previous_hash'] != self.hash(previous_block):
                return False

            # 检查proof是否有效
            if not self.valid_proof(previous_block['previous_hash'], previous_block['proof'], current_block['proof']):
                return False

        return True

    def hash(self, block):
        """计算区块的SHA-256哈希值"""
        block_string = json.dumps(block, sort_keys=True).encode()
        return hashlib.sha256(block_string).hexdigest()


def random_str():
    charset = string.ascii_letters + string.digits  # 字符集：大小写字母 + 数字
    result = ''.join(random.choices(charset, k=4))  # 随机选择4个字符
    return result

def random_num():
    num = random.uniform(0.0001, 9.9999)
    return num

def random_bool():
    value = random.choice([True, False])
    return value

def main():
    # 初始化区块链，并且拿到创始区块
    blockchain = MinimalBlockchain()
    print(blockchain.chain)

    miner_address = "0x8959404600a476dd57f2ca080fa4a69fcee73797"  # 挖矿人的地址
    next_block = True
    while next_block:
        # 开始直接挖一个区块

        # ======================================================= 为当前时刻添加一些交易
        if random_bool():  # 随机添加两笔交易
            blockchain.new_transaction(random_str(), random_str(), random_num())  #（from，to，amount）
            blockchain.new_transaction(random_str(), random_str(), random_num())  #（from，to，amount）
        else:  # 随机添加三笔交易
            blockchain.new_transaction(random_str(), random_str(), random_num())  #（from，to，amount）
            blockchain.new_transaction(random_str(), random_str(), random_num())  #（from，to，amount）
            blockchain.new_transaction(random_str(), random_str(), random_num())  #（from，to，amount）
        # print(blockchain.current_transactions)

        # ======================================================= 为当前时刻添加一些交易
        print("开始挖矿...")
        start_time = time.time()

        new_block = blockchain.mine(miner_address)

        end_time = time.time()

        print(f"挖矿完成! 耗时: {end_time - start_time:.2f}秒")
        print(f"新区块: {json.dumps(new_block, indent=2)}")

        # ======================================================= 验证区块链
        print(f"区块链是否有效? {blockchain.validate_chain()}")
        print(f"当前区块链长度: {len(blockchain.chain)}")

        # ======================================================= 是否需要下一个区块
        input_data = input("need next block(y or n)? ") 
        next_block = True if input_data == "y" else False
        

    # 打印当前所有区块
    for item in blockchain.chain:
        print(item)


if __name__ == "__main__":
    main()

