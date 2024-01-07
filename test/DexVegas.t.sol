// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../src/DexVegas.sol";
import { IDexVegas } from "../src/interfaces/IDexVegas.sol";
import { GMultipleChoiceFactory } from  "../src/GMultipleChoiceFactory.sol";
import { IGMultipleChoiceFactoryBase } from "../src/interfaces/IGMultipleChoiceFactory.sol";
import { DToken } from  "../src/DToken.sol";
import "../src/interfaces/IGMultipleChoice.sol";
import "./helper/MyERC20.sol";

contract DexVagasTest is Test {
    DexVegas vegas;
    address public admin;
    address public player1;
    address public player2;
    address public player3;
    address public player4;
    address public player5;

    function setUp() public {
        admin = makeAddr("admin");
        vm.startPrank(admin);
        vegas = new DexVegas();
        vm.stopPrank();
    }

    function test_add_game_type() public {
        string memory name = "game1";
        address factory = makeAddr("factory");

        vm.expectRevert("Only owner can add game");
        vegas.addGameType(name, factory);
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit IDexVegas.AddGameType(admin, name, factory);
        vegas.addGameType(name, factory);
        vm.stopPrank();

        (string memory _name, address _factory) = vegas.getGameTypeByName(name);
        assertEq(_name, name);
        assertEq(_factory, factory);
        assertEq(vegas.getGameTypeListLength(), 1);
        assertEq(vegas.getGameTypeList(0, 1)[0].name, name);
        assertEq(vegas.getGameTypeList(0, 1)[0].factory, factory);

        string memory name2 = "game2";
        address factory2 = makeAddr("factory2");
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit IDexVegas.AddGameType(admin, name2, factory2);
        vegas.addGameType(name2, factory2);
        vm.stopPrank();

        (string memory _name2, address _factory2) = vegas.getGameTypeByName(name2);
        assertEq(_name2, name2);
        assertEq(_factory2, factory2);
        assertEq(vegas.getGameTypeListLength(), 2);
        assertEq(vegas.getGameTypeList(0, 2)[0].name, name);
        assertEq(vegas.getGameTypeList(0, 2)[0].factory, factory);
        assertEq(vegas.getGameTypeList(0, 2)[1].name, name2);
        assertEq(vegas.getGameTypeList(0, 2)[1].factory, factory2);
    }

    function test_add_multiple_choice_game_integration_test() public {
        string memory gameName = "mutiple choice game";
        vm.startPrank(admin);
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        DToken dToken = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);
        GMultipleChoiceFactory factory = new GMultipleChoiceFactory(address(dToken));
        vegas.addGameType(gameName, address(factory));
        vm.stopPrank();

        vm.startPrank(admin);
        (, address factoryAddress) = vegas.getGameTypeByName(gameName);
        require(factoryAddress == address(factory));
        string[] memory options = new string[](2);
        options[0] = "pikachu";
        options[1] = "charmander";
        uint startBetTime = 1704250005;
        uint closeBetTime = 1704250105;
        uint lotteryDrawTime = 1704250205;
        IGMultipleChoiceFactoryBase.CreateGameParams memory createGameParams = IGMultipleChoiceFactoryBase.CreateGameParams({
            name: "pokemon",
            description: "pokemon game",
            minAmount: 0,
            maxAmount: 0,
            startBetTime: startBetTime,
            closeBetTime: closeBetTime,
            lotteryDrawTime: lotteryDrawTime,
            options: options,
            playerUpperLimit: 0,
            whitelistMerkleRoot: bytes32(0)
        });
        address gameAddress = GMultipleChoiceFactory(factoryAddress).createGame(createGameParams);
        vm.stopPrank();
        require(GMultipleChoiceFactory(factoryAddress).getGameList(0, 1)[0] == gameAddress);

        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
        player4 = makeAddr("player4");
        player5 = makeAddr("player5");
        _mintDToken(player1, underlyingToken, dToken);
        _mintDToken(player2, underlyingToken, dToken);
        _mintDToken(player3, underlyingToken, dToken);
        _mintDToken(player4, underlyingToken, dToken);
        _mintDToken(player5, underlyingToken, dToken);
        require(underlyingToken.balanceOf(address(dToken)) == 5000 * 10 ** underlyingToken.decimals());

        vm.warp(startBetTime);

        vm.startPrank(player1);
        dToken.approve(gameAddress, 1000 * 10 ** dToken.decimals());
        bytes32[] memory merkleProof = new bytes32[](0);
        uint256 tokenId1 = IGMultipleChoice(gameAddress).betting(10 * 10 ** dToken.decimals(), 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(player2);
        dToken.approve(gameAddress, 1000 * 10 ** dToken.decimals());
        IGMultipleChoice(gameAddress).betting(100 * 10 ** dToken.decimals(), 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(player3);
        dToken.approve(gameAddress, 1000 * 10 ** dToken.decimals());
        IGMultipleChoice(gameAddress).betting(60 * 10 ** dToken.decimals(), 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(player4);
        dToken.approve(gameAddress, 1000 * 10 ** dToken.decimals());
        uint256 tokenId4 = IGMultipleChoice(gameAddress).betting(15 * 10 ** dToken.decimals(), 0, merkleProof);
        vm.stopPrank();

        vm.startPrank(player5);
        dToken.approve(gameAddress, 1000 * 10 ** dToken.decimals());
        uint256 tokenId5 = IGMultipleChoice(gameAddress).betting(8 * 10 ** dToken.decimals(), 0, merkleProof);
        vm.stopPrank();

        vm.warp(closeBetTime);

        vm.startPrank(player5);
        vm.expectRevert(bytes("game is closed"));
        IGMultipleChoice(gameAddress).betting(8 * 1e18, 0, merkleProof);
        vm.stopPrank();

        vm.warp(lotteryDrawTime);
        vm.startPrank(admin);
        IGMultipleChoice(gameAddress).setAnswer(0);
        vm.stopPrank();

        assertEq(IGMultipleChoice(gameAddress).totalBettingAmount(), 193 * 1e18);
        assertEq(IGMultipleChoice(gameAddress).totalAwardAmount(), 191842 * 1e15);
        assertEq(dToken.balanceOf(factoryAddress), 193 * 1e15);
        assertEq(dToken.balanceOf(admin), 965 * 1e15);

        vm.startPrank(player1);
        vm.expectRevert(bytes("only winner can claim"));
        IGMultipleChoice(gameAddress).winnerClaimAward(tokenId1);
        vm.stopPrank();

        vm.startPrank(player4);
        // 125.114347826086956521
        uint256 claimedAmount = IGMultipleChoice(gameAddress).winnerClaimAward(tokenId4);
        assertEq(claimedAmount, IGMultipleChoice(gameAddress).totalAwardAmount()*15*1e18/(23*1e18));
        vm.stopPrank();

        vm.startPrank(player5);
        // 66.727652173913043478
        claimedAmount = IGMultipleChoice(gameAddress).winnerClaimAward(tokenId5);
        assertEq(claimedAmount, IGMultipleChoice(gameAddress).totalAwardAmount()*8*1e18/(23*1e18));
        // can not claim again
        vm.expectRevert(bytes("ticket has been claimed"));
        IGMultipleChoice(gameAddress).winnerClaimAward(tokenId5);
        vm.stopPrank();
    }

    function _mintDToken(address player, MyERC20 underlyingToken, DToken dToken) internal {
        uint mintAmount = 1000 * 10 ** underlyingToken.decimals();
        deal(address(underlyingToken), player, mintAmount);
        vm.startPrank(player);
        underlyingToken.approve(address(dToken), mintAmount);
        dToken.mint(mintAmount);
        vm.stopPrank();
    }
}