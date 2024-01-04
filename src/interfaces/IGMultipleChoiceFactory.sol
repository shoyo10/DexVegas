// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IGMultipleChoiceFactoryBase {
    /**
     * @notice create multiple choice game parameters
     * @param name name of the game
     * @param description description of the game
     * @param minAmount minimum bet amount
     * @param maxAmount maximum bet amount
     * @param startBetTime start time for betting
     * @param closeBetTime end time for betting
     * @param lotteryDrawTime after this time, can determine the result of the game
     * @param options options for the game
     * @param playerUpperLimit_ game player limit
     */
    struct CreateGameParams {
        string name;
        string description;
        uint256 minAmount; 
        uint256 maxAmount;
        uint startBetTime;
        uint closeBetTime;
        uint lotteryDrawTime;
        string[] options;
        uint256 playerUpperLimit;
    }
}

interface IGMultipleChoiceFactory is IGMultipleChoiceFactoryBase {
    event GameMultipleChoiceCreated(address indexed creator, address indexed gameAddress);
}