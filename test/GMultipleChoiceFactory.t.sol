// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { DToken } from  "../src/DToken.sol";
import { IGMultipleChoiceFactory } from "../src/interfaces/IGMultipleChoiceFactory.sol";
import { GMultipleChoiceFactory } from  "../src/GMultipleChoiceFactory.sol";
import { GMultipleChoice } from "../src/GMultipleChoice.sol";
import "./helper/MyERC20.sol";

contract GMultipleChoiceFactoryTest is Test, IGMultipleChoiceFactory {
    address public user1;
    DToken public dToken;
    GMultipleChoiceFactory public factory;
    address public gameAddress;
    CreateGameParams public createGameParams;

    function setUp() public {
        user1 = makeAddr("user1");

        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        dToken = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);
        factory = new GMultipleChoiceFactory(address(dToken));

        vm.startPrank(user1);
        string[] memory options = new string[](2);
        options[0] = "pikachu";
        options[1] = "charmander";
        createGameParams = CreateGameParams({
            name: "pokemon",
            description: "pokemon game",
            minAmount: 0,
            maxAmount: 0,
            startBetTime: 50,
            closeBetTime: 150,
            lotteryDrawTime: 200,
            options: options,
            playerUpperLimit: 0,
            whitelistMerkleRoot: bytes32(0)
        });
        vm.expectEmit(true, false, true, true);
        emit GameMultipleChoiceCreated(user1, address(0));
        gameAddress = factory.createGame(createGameParams);
        vm.stopPrank();
    }

    function test_constructor() public {
        assertEq(factory.admin(), address(this));
        assertEq(factory.dToken(), address(dToken));
    }

    function test_createGame() public {
        assertEq(factory.getGameListLength(), 1);
        assertEq(factory.getGameList(0, 1)[0], gameAddress);
        assertEq(factory.userOwnedGames(user1, 0, 1)[0], gameAddress);
        assertEq(factory.getParameters().options.length, 0);

        // create second game
        vm.startPrank(user1);
        string[] memory options = new string[](2);
        options[0] = "pikachu";
        options[1] = "charmander";
        CreateGameParams memory params = CreateGameParams({
            name: "pokemon",
            description: "pokemon game",
            minAmount: 0,
            maxAmount: 0,
            startBetTime: block.timestamp,
            closeBetTime: block.timestamp + 100,
            lotteryDrawTime: block.timestamp + 200,
            options: options,
            playerUpperLimit: 0,
            whitelistMerkleRoot: bytes32(0)
        });
        vm.expectEmit(true, false, true, true);
        emit GameMultipleChoiceCreated(user1, address(0));
        address gameAddress2 = factory.createGame(params);
        vm.stopPrank();
        assertEq(factory.getGameListLength(), 2);
        assertEq(factory.getGameList(1, 2)[0], gameAddress2);
        address[] memory ownedGames = factory.userOwnedGames(user1, 0, 2);
        assertEq(ownedGames[0], gameAddress);
        assertEq(ownedGames[1], gameAddress2);
        assertEq(factory.getParameters().options.length, 0);
    }

    function test_GMultipleChoice_constructor() public {
        GMultipleChoice game = GMultipleChoice(gameAddress);
        assertEq(game.gameName(), createGameParams.name);
        assertEq(game.gameDescription(), createGameParams.description);
        assertEq(game.factory(), address(factory));
        assertEq(game.creator(), user1);
        assertEq(game.minAmount(), createGameParams.minAmount);
        assertEq(game.maxAmount(), createGameParams.maxAmount);
        assertEq(game.startBetTime(), createGameParams.startBetTime);
        assertEq(game.closeBetTime(), createGameParams.closeBetTime);
        assertEq(game.lotteryDrawTime(), createGameParams.lotteryDrawTime);
        assertEq(game.playerUpperLimit(), factory.defaultGamePlayerUpperLimit());
        assertEq(game.getOptionsLength(), 2);
        assertEq(game.options(0), createGameParams.options[0]);
        assertEq(game.options(1), createGameParams.options[1]);
        assertEq(game.dToken(), address(dToken));

        // test minAmount, maxAmount, playerUpperLimit not 0 case
        vm.startPrank(user1);
        string[] memory options = new string[](2);
        options[0] = "pikachu";
        options[1] = "charmander";
        CreateGameParams memory params = CreateGameParams({
            name: "pokemon",
            description: "pokemon game",
            minAmount: 10,
            maxAmount: 1000,
            startBetTime: 50,
            closeBetTime: 150,
            lotteryDrawTime: 200,
            options: options,
            playerUpperLimit: 3,
            whitelistMerkleRoot: bytes32(0)
        });
        vm.expectEmit(true, false, true, true);
        emit GameMultipleChoiceCreated(user1, address(0));
        address gameAddress2 = factory.createGame(params);
        vm.stopPrank();

        game = GMultipleChoice(gameAddress2);
        assertEq(game.minAmount(), params.minAmount);
        assertEq(game.maxAmount(), params.maxAmount);
        assertEq(game.playerUpperLimit(), params.playerUpperLimit);
    }

    function test_admin_createGame() public {
        string[] memory options = new string[](2);
        options[0] = "pikachu";
        options[1] = "charmander";
        CreateGameParams memory params = CreateGameParams({
            name: "pokemon",
            description: "pokemon game",
            minAmount: 0,
            maxAmount: 0,
            startBetTime: 50,
            closeBetTime: 150,
            lotteryDrawTime: 200,
            options: options,
            playerUpperLimit: 0,
            whitelistMerkleRoot: bytes32(0)
        });
        vm.expectEmit(true, false, true, true);
        emit GameMultipleChoiceCreated(address(this), address(0));
        address gameAddress2 = factory.createGame(params);

        assertEq(factory.getGameListLength(), 2);
        assertEq(factory.getGameList(1, 2)[0], gameAddress2);
        address[] memory ownedGames = factory.userOwnedGames(address(this), 0, 2);
        assertEq(ownedGames.length, 1);
        assertEq(ownedGames[0], gameAddress2);
        assertEq(factory.getParameters().options.length, 0);

        GMultipleChoice game = GMultipleChoice(gameAddress2);
        assertEq(game.playerUpperLimit(), type(uint256).max);
    }
}