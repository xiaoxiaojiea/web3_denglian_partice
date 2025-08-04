from cryptography.hazmat.primitives.asymmetric import rsa, padding
from cryptography.hazmat.primitives import hashes, serialization
import hashlib
import base64


"""
原理解析：
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
"""


# 生成 RSA 2048 密钥对
def generate_keys():
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    public_key = private_key.public_key()
    return private_key, public_key

# PoW: 找到一个 nonce，使得 sha256(nickname + nonce) 以4个0开头
def pow_challenge(nickname: str):
    nonce = 0
    while True:
        msg = f"{nickname}{nonce}"
        digest = hashlib.sha256(msg.encode()).hexdigest()
        if digest.startswith("0000"):
            return msg, digest, nonce
        nonce += 1

# 使用私钥对msg签名
def sign_message(private_key, message: str) -> bytes:
    signature = private_key.sign(
        message.encode(),
        padding.PKCS1v15(),
        hashes.SHA256()
    )
    return signature

# 使用公钥验证签名后的msg是正确
def verify_signature(public_key, message: str, signature: bytes) -> bool:
    try:
        public_key.verify(
            signature,

            message.encode(),
            padding.PKCS1v15(),
            hashes.SHA256()
        )

        return True
    except Exception:
        return False

# 主函数流程
def main():
    # 寻找符合工作量证明的nonce
    nickname = "0x8959404600a476dd57f2ca080fa4a69fcee73797"
    print(f"开始 PoW 寻找 nonce 使 SHA256({nickname} + nonce) 以0000开头...")
    message, hash_digest, nonce = pow_challenge(nickname)
    print(f"找到msg: '{message}', 哈希: {hash_digest}, nonce: {nonce}")

    # 生成密钥对
    priv, pub = generate_keys()  # 私钥（加密），公钥（解密）

    # 使用私钥对msg签名
    signature = sign_message(priv, message)
    print(f"签名（base64）: {base64.b64encode(signature).decode()}")

    # 使用公钥验证签名后的msg是正确
    is_valid = verify_signature(pub, message, signature)
    print(f"验证签名结果: {'✅成功' if is_valid else '❌失败'}")

if __name__ == "__main__":
    main()
