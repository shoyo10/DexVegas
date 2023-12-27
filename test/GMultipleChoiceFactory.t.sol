// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import { DToken } from  "../src/DToken.sol";
import { IGMultipleChoiceFactory } from "../src/interfaces/IGMultipleChoiceFactory.sol";
import { GMultipleChoiceFactory } from  "../src/GMultipleChoiceFactory.sol";
import "./helper/MyERC20.sol";

contract GMultipleChoiceFactoryTest is Test, IGMultipleChoiceFactory {
    address public user1;
    DToken public dToken;
    GMultipleChoiceFactory public factory;

    function setUp() public {
        user1 = payable(makeAddr("user1"));

        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        dToken = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);
        factory = new GMultipleChoiceFactory(address(dToken));
    }

    function test_constructor() public {
        assertEq(factory.owner(), address(this));
        assertEq(factory.dToken(), address(dToken));
    }

    function test_createGame() public {
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
            playerUpperLimit: 0
        });
        vm.expectEmit(true, false, true, true);
        emit GameMultipleChoiceCreated(user1, address(0));
        address gameAddress = factory.createGame(params);
        vm.stopPrank();
    }
}