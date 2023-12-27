// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./GMultipleChoiceDeployer.sol";
import "./interfaces/IGMultipleChoiceFactory.sol";

contract GMultipleChoiceFactory is IGMultipleChoiceFactory, GMultipleChoiceDeployer {
    address public owner;
    address[] public gameList;
    address public dToken;
    /// @dev The user address to game address list
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
     */
    function createGame(CreateGameParams calldata params_) external returns (address gameAddress) {
        uint256 playerUpperLimit = defaultGamePlayerUpperLimit;
        address creator = msg.sender;
        if (creator == owner) {
            playerUpperLimit = type(uint256).max;
        }
        require(params_.playerUpperLimit <= playerUpperLimit, "playerUpperLimit must be less than defaultGamePlayerUpperLimit");
        if (params_.playerUpperLimit > 0) {
            playerUpperLimit = params_.playerUpperLimit;
        }
        Parameters memory params = Parameters({
            dToken: dToken,
            name: params_.name,
            description: params_.description,
            factory: address(this),
            creator: creator,
            minAmount: params_.minAmount,
            maxAmount: params_.maxAmount,
            startBetTime: params_.startBetTime,
            closeBetTime: params_.closeBetTime,
            lotteryDrawTime: params_.lotteryDrawTime,
            playerUpperLimit: playerUpperLimit,
            options: params_.options
        });
        gameAddress = deploy(params);
        gameList.push(gameAddress);
        userGames[creator].push(gameAddress);

        emit GameMultipleChoiceCreated(creator, gameAddress);
    }

    function setPlayerUpperLimit(uint256 limit) external onlyOwner {
        require(limit > 0, "Limit must be greater than 0");
        defaultGamePlayerUpperLimit = limit;
    }
}
