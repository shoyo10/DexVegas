// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./GMultipleChoiceDeployer.sol";

contract GMultipleChoiceFactory is GMultipleChoiceDeployer {
    address public owner;
    address[] public gameList;
    mapping(address => address[]) public userGames;
    uint256 playerUpperLimit = 4;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /// @param minAmount minimum bet amount
    /// @param maxAmount maximum bet amount
    /// @param closeBetTime end time for betting
    /// @param lotteryDrawTime after this time, can determine the result of the game
    function createGame(
        uint256 minAmount, 
        uint256 maxAmount,
        uint closeBetTime,
        uint lotteryDrawTime,
        string[] memory choose
    ) external returns (address gameAddress) {
        if (msg.sender == owner) {
            playerUpperLimit = type(uint256).max;
        }
        gameAddress = deploy(address(this), msg.sender, minAmount, maxAmount, closeBetTime, lotteryDrawTime, playerUpperLimit, choose);
        gameList.push(gameAddress);
        userGames[msg.sender].push(gameAddress);
    }

    function setPlayerUpperLimit(uint256 limit) external onlyOwner {
        require(limit > 0, "Limit must be greater than 0");
        playerUpperLimit = limit;
    }
}
