// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/MemeToken.sol";
import "../src/MemeFactory.sol";

contract MemeFactoryTest is Test {
    MemeFactory public factory; // 被测的工厂合约
    address public projectOwner; // 平台方收取手续费的地址
    address public creator; // 发起代币的项目创建者
    address public buyer; // 买代币的人

    // 测试参数
    string constant NAME = "MEME";
    string constant SYMBOL = "MM";
    uint256 constant TOTAL_SUPPLY = 1000000 * 10 ** 18; // 1,000,000 tokens
    uint256 constant PER_MINT = 1000 * 10 ** 18; // 1,000 tokens per mint
    uint256 constant PRICE = 0.0001 ether; // 0.0001 ETH per token

    function setUp() public {
        // makeAddr("xxx") → 生成测试钱包地址
        projectOwner = makeAddr("projectOwner"); // 把平台方地址设为 projectOwner
        creator = makeAddr("creator");
        buyer = makeAddr("buyer");

        // 给测试账户一些 ETH
        vm.deal(creator, 10 ether);
        vm.deal(buyer, 10 ether);

        // 部署工厂合约
        factory = new MemeFactory(projectOwner);
    }

    // 部署代币，验证代币信息
    function testDeployInscription() public {
        // 用 creator 身份调用 deployInscription，部署新代币
        vm.startPrank(creator);

        // 得到一个代币地址 tokenAddr
        address tokenAddr = factory.deployInscription(
            NAME,
            SYMBOL,
            TOTAL_SUPPLY,
            PER_MINT,
            PRICE
        );

        vm.stopPrank();

        // 验证代币部署成功
        assertTrue(factory.deployedTokens(tokenAddr), "Token not deployed");

        // 验证代币参数
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.totalSupply_(), TOTAL_SUPPLY, "Incorrect total supply");
        assertEq(token.perMint(), PER_MINT, "Incorrect per mint amount");
        assertEq(token.price(), PRICE, "Incorrect price");
        assertEq(token.memeCreator(), creator, "Incorrect creator");
        assertEq(token.name(), NAME, "Incorrect name");
        assertEq(token.symbol(), SYMBOL, "Incorrect symbol");

        // 打印 name 和 symbol
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
    }

    // 铸造代币
    function testMintInscription() public {
        // 部署一个代币
        vm.startPrank(creator);
        address tokenAddr = factory.deployInscription(
            NAME,
            SYMBOL,
            TOTAL_SUPPLY,
            PER_MINT,
            PRICE
        );
        vm.stopPrank();

        // 记录初始余额
        uint256 initialProjectBalance = projectOwner.balance;
        uint256 initialCreatorBalance = creator.balance;

        // 计算所需支付金额
        uint256 requiredAmount = (PER_MINT * PRICE) / 10 ** 18;

        // 买家铸造代币
        vm.startPrank(buyer);
        factory.mintInscription{value: requiredAmount}(tokenAddr);
        vm.stopPrank();

        // 验证代币铸造成功
        MemeToken token = MemeToken(tokenAddr);
        assertEq(token.balanceOf(buyer), PER_MINT, "Incorrect minted amount");
        assertEq(
            token.mintedAmount(),
            PER_MINT,
            "Incorrect total minted amount"
        );

        // 验证费用分配
        uint256 projectFee = (requiredAmount * factory.PROJECT_FEE_PERCENT()) /
            100;
        uint256 creatorFee = requiredAmount - projectFee;

        assertEq(
            projectOwner.balance,
            initialProjectBalance + projectFee,
            "Incorrect project fee"
        );
        assertEq(
            creator.balance,
            initialCreatorBalance + creatorFee,
            "Incorrect creator fee"
        );
    }


    // 多次铸造
    function testMintMultipleTimes() public {
        // 部署代币
        vm.startPrank(creator);
        address tokenAddr = factory.deployInscription(
            NAME,
            SYMBOL,
            TOTAL_SUPPLY,
            PER_MINT,
            PRICE
        );
        vm.stopPrank();

        // 计算所需支付金额
        uint256 requiredAmount = (PER_MINT * PRICE) / 10 ** 18;

        // 多次铸造，但限制次数以避免超过总供应量
        // 由于 TOTAL_SUPPLY = 1,000,000 * 10**18 且 PER_MINT = 1,000 * 10**18
        // 理论上最多可以铸造 1000 次，但为安全起见，我们只铸造几次进行测试
        uint256 testMints = 5; // 只测试铸造 5 次，避免测试耗时过长

        for (uint256 i = 0; i < testMints; i++) {
            vm.startPrank(buyer);
            factory.mintInscription{value: requiredAmount}(tokenAddr);
            vm.stopPrank();

            // 验证铸造数量
            MemeToken token = MemeToken(tokenAddr);
            assertEq(
                token.mintedAmount(),
                PER_MINT * (i + 1),
                "Incorrect total minted amount"
            );
        }

        // 验证可以继续铸造（因为我们只铸造了少量代币）
        vm.startPrank(buyer);
        factory.mintInscription{value: requiredAmount}(tokenAddr);
        vm.stopPrank();

        // 验证铸造后的总量
        MemeToken token = MemeToken(tokenAddr);
        assertEq(
            token.mintedAmount(),
            PER_MINT * (testMints + 1),
            "Incorrect final minted amount"
        );
        
    }
}
