// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { DToken } from  "../../src/DToken.sol";
import { GMultipleChoiceFactory } from  "../../src/GMultipleChoiceFactory.sol";
import { IGMultipleChoiceFactory } from "../../src/interfaces/IGMultipleChoiceFactory.sol";
import "./MyERC20.sol";

contract GMultipleChoiceSetUp is Test, IGMultipleChoiceFactory {
    address public admin;
    address public gameCreator;
    DToken public dToken;
    GMultipleChoiceFactory public factory;
    address public gameAddress;
    CreateGameParams public createGameParams;
    uint public startBetTime = 1704250005;
    uint public closeBetTime = 1704250105;
    uint public lotteryDrawTime = 1704250205;

    function setUp() public virtual {
        admin = makeAddr("admin");
        gameCreator = makeAddr("gameCreator");

        vm.startPrank(admin);
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        dToken = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);
        factory = new GMultipleChoiceFactory(address(dToken));
        vm.stopPrank();

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
            whiteListMerkleRoot: bytes32(0)
        });
        gameAddress = factory.createGame(createGameParams);
        vm.stopPrank();

        vm.label(address(dToken), "DToken");
        vm.label(address(factory), "factory");
        vm.label(gameAddress, "MultipleChoiceGame");
    }
}