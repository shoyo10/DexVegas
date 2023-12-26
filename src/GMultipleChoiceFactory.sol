// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./GMultipleChoiceDeployer.sol";

contract GMultipleChoiceFactory is GMultipleChoiceDeployer {
    address public owner;
    address[] public gameList;
    address public dToken;
    mapping(address => address[]) public userGames;
    uint256 defaultGamePlayerUpperLimit = 4;

    constructor(address dToken_) {
        owner = msg.sender;
        dToken = dToken_;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /**
     * @notice user can create a game
     * @param name name of the game
     * @param description description of the game
     * @param minAmount minimum bet amount
     * @param maxAmount maximum bet amount
     * @param closeBetTime end time for betting
     * @param lotteryDrawTime after this time, can determine the result of the game
     * @param options options for the game
     */
    function createGame(
        string calldata name,
        string calldata description,
        uint256 minAmount, 
        uint256 maxAmount,
        uint startBetTime,
        uint closeBetTime,
        uint lotteryDrawTime,
        string[] memory options
    ) external returns (address gameAddress) {
        uint256 playerUpperLimit = defaultGamePlayerUpperLimit;
        if (msg.sender == owner) {
            playerUpperLimit = type(uint256).max;
        }
        Parameters memory params = Parameters({
            dToken: dToken,
            name: name,
            description: description,
            factory: address(this),
            initiator: msg.sender,
            minAmount: minAmount,
            maxAmount: maxAmount,
            startBetTime: startBetTime,
            closeBetTime: closeBetTime,
            lotteryDrawTime: lotteryDrawTime,
            playerUpperLimit: playerUpperLimit,
            options: options
        });
        gameAddress = deploy(params);
        gameList.push(gameAddress);
        userGames[msg.sender].push(gameAddress);
    }

    function setPlayerUpperLimit(uint256 limit) external onlyOwner {
        require(limit > 0, "Limit must be greater than 0");
        defaultGamePlayerUpperLimit = limit;
    }
}
