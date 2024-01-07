// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { GMultipleChoiceSetUp } from "./helper/GMultipleChoiceSetUp.sol";
import { IGMultipleChoice } from "../src/interfaces/IGMultipleChoice.sol";
import { GMultipleChoice } from "../src/GMultipleChoice.sol";

contract GMultipleChoiceTest is GMultipleChoiceSetUp {
    address public player1;
    address public player2;
    address public player3;

    IGMultipleChoice multipleChoiceGame;

    function setUp() public override {
        super.setUp();

        multipleChoiceGame = IGMultipleChoice(gameAddress);

        player1 = makeAddr("player1");
        player2 = makeAddr("player2");
        player3 = makeAddr("player3");
    }

    function test_betting() public {
        // test player1 bet 10 DToken on option 0
        bytes32[] memory merkleProof = new bytes32[](0);
        vm.startPrank(player1);
        vm.expectRevert(bytes("game is not started"));
        multipleChoiceGame.betting(10, 0, merkleProof);
        
        vm.warp(startBetTime);
        vm.expectRevert(bytes("buyer has not enough DToken"));
        multipleChoiceGame.betting(10, 0, merkleProof);

        deal(address(dToken), player1, 10000);

        vm.expectRevert(bytes("optionIndex is invalid"));
        multipleChoiceGame.betting(10, 2, merkleProof);

        dToken.approve(gameAddress, 100);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.Betting(player1, 1, 10, 0);
        uint256 tokenId = multipleChoiceGame.betting(10, 0, merkleProof);
        assertEq(tokenId, 1);
        vm.stopPrank();

        (uint256 optionIndex, uint256 amount, IGMultipleChoice.LotteryTicketClaimed claimStatus) = multipleChoiceGame.getLotteryTicket(tokenId);
        assertEq(optionIndex, 0);
        assertEq(amount, 10);
        assertEq(uint256(claimStatus), 0);

        assertEq(dToken.balanceOf(gameAddress), 10);
        assertEq(multipleChoiceGame.totalBettingAmount(), 10);
        assertEq(multipleChoiceGame.optionBettingAmount(0), 10);
        assertEq(GMultipleChoice(gameAddress).ownerOf(tokenId), player1);

        // test player1 bet 8000 DToken on option 1
        vm.startPrank(player1);
        dToken.approve(gameAddress, 10000);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.Betting(player1, 2, 8000, 1);
        uint256 tokenId2 = multipleChoiceGame.betting(8000, 1, merkleProof);
        assertEq(tokenId2, 2);
        vm.stopPrank();

        (optionIndex, amount, claimStatus) = multipleChoiceGame.getLotteryTicket(tokenId2);
        assertEq(optionIndex, 1);
        assertEq(amount, 8000);
        assertEq(uint256(claimStatus), 0);
        assertEq(dToken.balanceOf(gameAddress), 8010);
        assertEq(multipleChoiceGame.totalBettingAmount(), 8010);
        assertEq(multipleChoiceGame.optionBettingAmount(0), 10);
        assertEq(multipleChoiceGame.optionBettingAmount(1), 8000);

        // test player2 bet 1000 DToken on option 0
        vm.startPrank(player2);
        deal(address(dToken), player2, 10000);
        dToken.approve(gameAddress, 10000);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.Betting(player2, 3, 1000, 0);
        uint256 tokenId3 = multipleChoiceGame.betting(1000, 0, merkleProof);
        assertEq(tokenId3, 3);
        vm.stopPrank();

        (optionIndex, amount, claimStatus) = multipleChoiceGame.getLotteryTicket(tokenId3);
        assertEq(optionIndex, 0);
        assertEq(amount, 1000);
        assertEq(uint256(claimStatus), 0);
        assertEq(dToken.balanceOf(gameAddress), 9010);
        assertEq(multipleChoiceGame.totalBettingAmount(), 9010);
        assertEq(multipleChoiceGame.optionBettingAmount(0), 1010);
        assertEq(multipleChoiceGame.optionBettingAmount(1), 8000);
        assertEq(GMultipleChoice(gameAddress).ownerOf(tokenId3), player2);

        vm.warp(closeBetTime);
        vm.startPrank(player2);
        vm.expectRevert(bytes("game is closed"));
        multipleChoiceGame.betting(1, 0, merkleProof);
        vm.stopPrank();
    }

    function test_betting_total_amount_overflow() public {
        vm.warp(startBetTime);

        bytes32[] memory merkleProof = new bytes32[](0);
        vm.startPrank(player1);
        deal(address(dToken), player1, type(uint256).max);
        dToken.approve(gameAddress, type(uint256).max);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.Betting(player1, 1, type(uint256).max, 0);
        multipleChoiceGame.betting(type(uint256).max, 0, merkleProof);
        vm.stopPrank();

        vm.startPrank(player2);
        deal(address(dToken), player2, 10000);
        dToken.approve(gameAddress, 10000);
        vm.expectRevert(bytes("totalBettingAmount overflow"));
        multipleChoiceGame.betting(1, 1, merkleProof);
        vm.stopPrank();
    }

    function test_betting_whitelist() public {
        vm.warp(startBetTime);

        /**
         * merkle root is generated from helper/merkletreejs/merkletree.js
         * player1, player2, player3, and gameCreator are in whitelist
         * player1 address is 0x7026B763CBE7d4E72049EA67E89326432a50ef84
         * player2 address is 0xEb0A3b7B96C1883858292F0039161abD287E3324
         * player3 address is 0xcC37919fDb8E2949328cDB49E8bAcCb870d0c9f3
         * gameCreator address is 0x228EBeEbaCb93F12C10d34aBFDCeaF400e894F45
         */

        // create a game with whitelist setting
        vm.startPrank(gameCreator);
        string[] memory options = new string[](2);
        options[0] = "pikachu";
        options[1] = "charmander";
        createGameParams = CreateGameParams({
            name: "pokemon",
            description: "pokemon game",
            minAmount: 0,
            maxAmount: 0,
            startBetTime: startBetTime,
            closeBetTime: closeBetTime,
            lotteryDrawTime: lotteryDrawTime,
            options: options,
            playerUpperLimit: 0,
            whitelistMerkleRoot: 0x9f593cdf92e93670ace4ebc0c7a8568c3e943e6a6324cc08cb31e1fdb73a8d5b
        });
        address gameAddress2 = factory.createGame(createGameParams);
        vm.stopPrank();

        vm.startPrank(player1);
        deal(address(dToken), player1, 10000);
        dToken.approve(gameAddress2, 100);
        bytes32[] memory merkleProof = new bytes32[](2);
        merkleProof[0] = 0x305d9619d81293188079d4bd630f530b1b7dc7ead576467cf09f3bdd42da00f7;
        merkleProof[1] = 0x39aba7c26db2ffabfe00aa49ad0a1d90455a486b965819b010b648272c9b0a8d;
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.Betting(player1, 1, 10, 0);
        uint256 tokenId = IGMultipleChoice(gameAddress2).betting(10, 0, merkleProof);
        assertEq(tokenId, 1);
        vm.stopPrank();
        
        vm.startPrank(admin);
        deal(address(dToken), admin, 10000);
        dToken.approve(gameAddress2, 100);
        vm.expectRevert("buyer is not in whitelist");
        IGMultipleChoice(gameAddress2).betting(10, 0, merkleProof);
        vm.stopPrank();
    }

    function test_setAnswer() public {
        // prepare test data
        vm.warp(startBetTime);
        deal(address(dToken), player1, type(uint256).max);
        deal(address(dToken), player2, type(uint256).max);
        deal(address(dToken), player3, type(uint256).max);

        bytes32[] memory merkleProof = new bytes32[](0);
        vm.startPrank(player1);
        dToken.approve(gameAddress, type(uint256).max);
        multipleChoiceGame.betting(50, 0, merkleProof);
        vm.stopPrank();

        vm.startPrank(player2);
        dToken.approve(gameAddress, type(uint256).max);
        multipleChoiceGame.betting(30, 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(player3);
        dToken.approve(gameAddress, type(uint256).max);
        multipleChoiceGame.betting(20, 1, merkleProof);
        multipleChoiceGame.betting(40, 1, merkleProof);
        vm.stopPrank();

        // start test setAnswer
        vm.expectRevert(bytes("only creator can set answer index"));
        multipleChoiceGame.setAnswer(0);

        vm.startPrank(gameCreator);
        vm.expectRevert(bytes("answer index is invalid"));
        multipleChoiceGame.setAnswer(2);
        vm.expectRevert(bytes("lottery draw time is not reached"));
        multipleChoiceGame.setAnswer(1);
        vm.warp(lotteryDrawTime);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.SetAnswer(gameCreator, 1);
        multipleChoiceGame.setAnswer(1);
        vm.stopPrank();

        assertEq(multipleChoiceGame.answerIndex(), 1);
        assertEq(dToken.balanceOf(address(factory)), 0);
        assertEq(dToken.balanceOf(gameCreator), 0);
        assertEq(multipleChoiceGame.totalAwardAmount(), 140);

        vm.startPrank(gameCreator);
        vm.expectRevert(bytes("answer index has been set"));
        multipleChoiceGame.setAnswer(0);
        vm.stopPrank();
    }

    function test_setAnswer_fee() public {
        vm.warp(startBetTime);
        deal(address(dToken), player1, type(uint256).max);
        deal(address(dToken), player2, type(uint256).max);
        deal(address(dToken), player3, type(uint256).max);

        bytes32[] memory merkleProof = new bytes32[](0);
        vm.startPrank(player1);
        dToken.approve(gameAddress, type(uint256).max);
        multipleChoiceGame.betting(500, 0, merkleProof);
        vm.stopPrank();

        vm.startPrank(player2);
        dToken.approve(gameAddress, type(uint256).max);
        multipleChoiceGame.betting(300, 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(player3);
        dToken.approve(gameAddress, type(uint256).max);
        multipleChoiceGame.betting(200, 1, merkleProof);
        multipleChoiceGame.betting(400, 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(gameCreator);
        vm.warp(lotteryDrawTime);
        multipleChoiceGame.setAnswer(1);
        vm.stopPrank();

        assertEq(dToken.balanceOf(address(factory)), 1);
        assertEq(dToken.balanceOf(gameCreator), 7);
        assertEq(multipleChoiceGame.totalAwardAmount(), 1392);
    }

    function test_winnerClaimAward() public {
        // prepare test data
        vm.warp(startBetTime);
        deal(address(dToken), player1, 10000);
        deal(address(dToken), player2, 10000);
        deal(address(dToken), player3, 10000);

        bytes32[] memory merkleProof = new bytes32[](0);
        vm.startPrank(player1);
        dToken.approve(gameAddress, type(uint256).max);
        uint256 tokenId1 = multipleChoiceGame.betting(50, 0, merkleProof);
        vm.stopPrank();

        vm.startPrank(player2);
        dToken.approve(gameAddress, type(uint256).max);
        uint256 tokenId2 = multipleChoiceGame.betting(30, 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(player3);
        dToken.approve(gameAddress, type(uint256).max);
        uint256 tokenId3 = multipleChoiceGame.betting(20, 1, merkleProof);
        uint256 tokenId4 = multipleChoiceGame.betting(40, 1, merkleProof);
        vm.stopPrank();

        assertEq(dToken.balanceOf(gameAddress), 140);

        // start test winnerClaimAward
        vm.expectRevert("answer index is not set");
        multipleChoiceGame.winnerClaimAward(1);

        vm.startPrank(gameCreator);
        vm.warp(lotteryDrawTime);
        multipleChoiceGame.setAnswer(1);
        vm.stopPrank();

        vm.expectRevert("only NFT owner can claim");
        multipleChoiceGame.winnerClaimAward(1);

        vm.startPrank(player1);
        vm.expectRevert("only winner can claim");
        multipleChoiceGame.winnerClaimAward(tokenId1);
        vm.stopPrank();

        vm.startPrank(player2);
        // 140*30/90 = 46
        uint256 expectClaimAmount = 140*30/uint256(90);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.WinnerClaim(player2, tokenId2, expectClaimAmount);
        uint256 claimAmount = multipleChoiceGame.winnerClaimAward(tokenId2);
        vm.expectRevert("ticket has been claimed");
        multipleChoiceGame.winnerClaimAward(tokenId2);
        vm.stopPrank();
        assertEq(claimAmount, expectClaimAmount);
        assertEq(dToken.balanceOf(player2), 10016);
        uint256 gameContractLeftAmount = 140-expectClaimAmount;
        assertEq(dToken.balanceOf(gameAddress), gameContractLeftAmount);

        vm.startPrank(player3);
        // 140*20/90 = 31
        expectClaimAmount = 140*20/uint256(90);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.WinnerClaim(player3, tokenId3, expectClaimAmount);
        claimAmount = multipleChoiceGame.winnerClaimAward(tokenId3);
        vm.stopPrank();
        gameContractLeftAmount -= expectClaimAmount;
        assertEq(claimAmount, expectClaimAmount);
        assertEq(dToken.balanceOf(player3), 9971);
        assertEq(dToken.balanceOf(gameAddress), gameContractLeftAmount);

        vm.startPrank(player3);
        // 140*40/90 = 62
        expectClaimAmount = 140*40/uint256(90);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.WinnerClaim(player3, tokenId4, expectClaimAmount);
        claimAmount = multipleChoiceGame.winnerClaimAward(tokenId4);
        vm.stopPrank();
        gameContractLeftAmount -= expectClaimAmount;
        assertEq(claimAmount, expectClaimAmount);
        assertEq(dToken.balanceOf(player3), 10033);
        assertEq(dToken.balanceOf(gameAddress), gameContractLeftAmount);
    }

    /// test winner claim award which available prize was already reduced fee
    function test_winnerClaimAward_fee_reduced() public {
        // prepare test data
        vm.warp(startBetTime);
        deal(address(dToken), player1, 10000);
        deal(address(dToken), player2, 10000);
        deal(address(dToken), player3, 10000);

        bytes32[] memory merkleProof = new bytes32[](0);
        vm.startPrank(player1);
        dToken.approve(gameAddress, type(uint256).max);
         multipleChoiceGame.betting(500, 0, merkleProof);
        vm.stopPrank();

        vm.startPrank(player2);
        dToken.approve(gameAddress, type(uint256).max);
        uint256 tokenId2 = multipleChoiceGame.betting(300, 1, merkleProof);
        vm.stopPrank();

        vm.startPrank(player3);
        dToken.approve(gameAddress, type(uint256).max);
        uint256 tokenId3 = multipleChoiceGame.betting(200, 1, merkleProof);
        uint256 tokenId4 = multipleChoiceGame.betting(400, 1, merkleProof);
        vm.stopPrank();

        assertEq(dToken.balanceOf(gameAddress), 1400);

        vm.startPrank(gameCreator);
        vm.warp(lotteryDrawTime);
        multipleChoiceGame.setAnswer(1);
        vm.stopPrank();

        assertEq(multipleChoiceGame.totalAwardAmount(), 1392);

        vm.startPrank(player2);
        // 1392*300/900 = 464
        uint256 expectClaimAmount = 1392*300/uint256(900);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.WinnerClaim(player2, tokenId2, expectClaimAmount);
        uint256 claimAmount = multipleChoiceGame.winnerClaimAward(tokenId2);
        vm.stopPrank();
        assertEq(claimAmount, expectClaimAmount);
        assertEq(dToken.balanceOf(player2), 10164);
        uint256 gameContractLeftAmount = 1392-expectClaimAmount;
        assertEq(dToken.balanceOf(gameAddress), gameContractLeftAmount);

        vm.startPrank(player3);
        // 1392*200/900 = 309
        expectClaimAmount = 1392*200/uint256(900);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.WinnerClaim(player3, tokenId3, expectClaimAmount);
        claimAmount = multipleChoiceGame.winnerClaimAward(tokenId3);
        vm.stopPrank();
        gameContractLeftAmount -= expectClaimAmount;
        assertEq(claimAmount, expectClaimAmount);
        assertEq(dToken.balanceOf(player3), 9709);
        assertEq(dToken.balanceOf(gameAddress), gameContractLeftAmount);

        vm.startPrank(player3);
        // 1392*400/900 = 618
        expectClaimAmount = 1392*400/uint256(900);
        vm.expectEmit(true, true, true, true);
        emit IGMultipleChoice.WinnerClaim(player3, tokenId4, expectClaimAmount);
        claimAmount = multipleChoiceGame.winnerClaimAward(tokenId4);
        vm.stopPrank();
        gameContractLeftAmount -= expectClaimAmount;
        assertEq(claimAmount, expectClaimAmount);
        assertEq(dToken.balanceOf(player3), 10327);
        assertEq(dToken.balanceOf(gameAddress), gameContractLeftAmount);
        console.log("gameContractLeftAmount: %d", gameContractLeftAmount);
    }
}