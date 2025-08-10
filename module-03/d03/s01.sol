// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract BaseERC721 {
    using Strings for uint256;
    using Address for address;

    string private _name;  // NFT名称
    string private _symbol;  // NFT符号
    string private _baseURI;  // NFT基础链接

    // NFT编号索引到的拥有者地址
    mapping(uint256 => address) private _owners;  // NFT唯一编号 -> 拥有者地址
    // 拥有者地址拥有的NFT数量
    mapping(address => uint256) private _balances;  // 拥有者地址 -> NFT数量
    // 单个NFT授权给的地址（单个授权）
    mapping(uint256 => address) private _tokenApprovals;  // NFT唯一编号 -> 可以被操作的地址
    // 批量NFT授权给的地址（批量授权）
    mapping(address => mapping(address => bool)) private _operatorApprovals;  // NFT拥有者 -> 授权的地址 -> 是否可操作自己的所有NFT

    // 事件：转账
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    // 事件：授权
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    // 事件：批量授权
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // 构造函数
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseURI = baseURI_;
    }

    // 返回token名称
    function name() public view returns (string memory) {
        return _name;
    }

    // 返回token符号
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // 返回NFT ID为tokenId的NFT URI（NFT都会存在一个链接的）
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(
            _exists(tokenId),  // 检查当前tokenId对应的NFT是否存在
            "ERC721Metadata: URI query for nonexistent token"
        );

        // 返回字符串URI
        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    // 为地址to铸造一个id为tokenId的NFT
    function mint(address to, uint256 tokenId) public {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;  // 该地址下的NFT数量+1
        _owners[tokenId] = to;  // 为该编号的NFT设置拥有者地址

        emit Transfer(address(0), to, tokenId);
    }

    // 查询某地址的NFT数量
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    // 查看某ID的NFT所属的地址
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        return owner;
    }

    // sender将某个NFT授权给地址to
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);  // 当前NFT的所有者
        require(to != owner, "ERC721: approval to current owner");

        // 当前NFT的所有者是sender or 当前NFT的所有者授权给sender了
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

       _approve(to, tokenId);
    }

    // 查看NFT的授权地址
    function getApproved(uint256 tokenId) public view returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    // 将sender的所有NFT对地址operator的授权修改为approved（可以是true，false）
    function setApprovalForAll(address operator, bool approved) public {
        address sender = msg.sender;
        require(operator != sender, "ERC721: approve to caller");
        
        // 授权（修改为true or false）
        _operatorApprovals[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    // 查看owner的nft是否全部授权给operator了
    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // 将NFT从from转移到to（替代转账）
    function transferFrom(address from, address to, uint256 tokenId) public {
        // 该NFT授权给了sender
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        // 转账
        _transfer(from, to, tokenId);
    }

    // 检查NFT是否存在（已经被mint了），true：存在；false：不存在
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);  // 检查NFT是否存在
    }

    // 检查spender是否有操作tokenId权限（3种情况）
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view returns (bool) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );

        address owner = ownerOf(tokenId);  // 当前NFT的所有者
        return (spender == owner ||   // spender是NFT所有者
                getApproved(tokenId) == spender ||  // spender是NFT的授权者
                isApprovedForAll(owner, spender));  // spender是 当前NFT的所有者 的所有NFT授权者
    }

    // 转账
    function _transfer(address from, address to, uint256 tokenId) internal {
        // 从from转出
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        // 转到地址to不能是地址0
        require(to != address(0), "ERC721: transfer to the zero address");

        // 转账的时候要清除该NFT的授权地址（就是将tokenId的唯一授权地址修改为地址0）
        _approve(address(0), tokenId);

        // 转账：跟coin操作是一个原理
        _balances[from] -= 1;  // from地址-1
        _balances[to] += 1;  // from地址+1
        _owners[tokenId] = to;  // 修改拥有者

        emit Transfer(from, to, tokenId);
    }

    // 授权地址to操作NFT（当to为0的时候就是清除NFT的授权地址）
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;

        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // 这个方法主要是方便**外部合约或平台（比如 OpenSea、LooksRare）**检测你的合约是否支持某个接口
    //    比如：IERC165(contractAddress).supportsInterface(0x80ac58cd)，如果返回 true，说明它支持 ERC721 标准。
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f;   // ERC165 Interface ID for ERC721Metadata
    }


    // ****** 下边的代码是 ERC721 标准里 Safe Transfer（安全转账）相关的实现，目的是在转 NFT 时保证不会把代币转进一个不会处理它的合约里，从而避免 NFT 永久卡死。 ******

    // 这个是 重载函数（overload），没有额外的 _data 参数时，会自动调用下面那个带 _data 的版本，并传一个空的 bytes
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    // 这个是完整版本的安全转账函数：
    //      1，权限检查：
    //          - 调用 _isApprovedOrOwner 检查 msg.sender 是否是：1）该 NFT 的持有人；2）被授权的地址（approve 或 setApprovalForAll）
    //      2，执行转账：
    //          - 调用 _safeTransfer 完成实际转账
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    // 这个函数才是真正的安全转账逻辑：
    //      1，调用 _transfer 改变 NFT 所有权（更新映射、触发 Transfer 事件）。
    //      2，调用 _checkOnERC721Received：
    //          - 如果 to 是普通用户地址（EOA），直接通过。
    //          - 如果 to 是合约地址，会调用它的 onERC721Received 方法，看看是否返回了正确的 magic value（0x150b7a02）。
    //          - 如果合约没实现这个方法或返回值不对，就 require 抛错，防止 NFT 被锁死在不支持的合约里。
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal {
        // 转账
        _transfer(from, to, tokenId);
        // 检查该转账是否合法
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }


    // safeTransferFrom 的核心安全检测机制，它用来判断接收方是否是能接收 NFT 的合约。
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        // 判断 to 是合约还是外部账户（在 Solidity 中，address.code.length 可以获取该地址的合约字节码长度。）
        //  1，如果 大于 0，说明 to 是合约地址。
        //  2，如果是 外部账户（EOA），直接返回 true，跳过检查。
        if (to.code.length > 0) {
            try
                /** 在 Solidity 里的语法结构是这样的
                 * try:
                 *     执行操作
                 * returns  (ReturnType varName) :
                 *     如果调用成功，并且没有 revert，就进入这里
                 * catch (bytes memory reason) :
                 *     如果调用 revert 或出错，就进入这里
                 */

                // 调用合约地址的 onERC721Received 方法，这是 ERC721 接收方合约必须实现的函数
                //      签名为：function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                // 这个方法必须返回固定的 magic value：IERC721Receiver.onERC721Received.selector // 0x150b7a02
                //      如果返回值不对，说明该合约不支持接收 NFT。
                return retval == IERC721Receiver.onERC721Received.selector;

            // 捕获异常
            } catch (bytes memory reason) {
                // reason.length == 0：表示没提供错误信息，直接用固定报错。
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {  // reason.length ！= 0：表示有自定义错误原因，用 assembly revert 原样抛出，保留错误信息。
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

}

// 最简版 ERC721 接收方合约，它的作用就是实现 ERC721 标准要求的 onERC721Received 接口，让它可以安全接收 NFT。
contract BaseERC721Receiver is IERC721Receiver {
    constructor() {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

}

contract BaseNoneReceiver {
    constructor() {}
}
