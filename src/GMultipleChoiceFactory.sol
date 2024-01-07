// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./GMultipleChoiceDeployer.sol";
import "./interfaces/IGMultipleChoiceFactory.sol";

contract GMultipleChoiceFactory is IGMultipleChoiceFactory, GMultipleChoiceDeployer {
    address public admin;
    address[] internal gameList;
    address public dToken;
    /// @dev The user address to game address list
    mapping(address => address[]) public userGames;
    uint256 public defaultGamePlayerUpperLimit = 4;

    constructor(address dToken_) {
        admin = msg.sender;
        dToken = dToken_;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    /**
     * @notice user can create a game
     */
    function createGame(CreateGameParams calldata params_) external returns (address gameAddress) {
        uint256 playerUpperLimit = defaultGamePlayerUpperLimit;
        address creator = msg.sender;
        if (creator == admin) {
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
            options: params_.options,
            whiteListMerkleRoot: params_.whiteListMerkleRoot
        });
        gameAddress = deploy(params);
        gameList.push(gameAddress);
        userGames[creator].push(gameAddress);

        emit GameMultipleChoiceCreated(creator, gameAddress);
    }

    function setPlayerUpperLimit(uint256 limit) external onlyAdmin {
        require(limit > 0, "Limit must be greater than 0");
        defaultGamePlayerUpperLimit = limit;
    }

    /**
     * @notice get multiple choice game list
     * @param startIdx The start index of game list
     * @param endIdx The end index of game list
     * @return The list of game address
     */
    function getGameList(uint startIdx, uint endIdx) external view returns (address[] memory) {
        require(startIdx < endIdx, "startIdx must be less than endIdx");
        require(endIdx <= gameList.length, "endIdx must be less than gameList length");
        address[] memory list = new address[](endIdx - startIdx);
        for (uint i = startIdx; i < endIdx; i++) {
            list[i - startIdx] = gameList[i];
        }
        return list;
    }

    /**
     * @notice get multiple choice game list length
     * @return The length of game list
     */
    function getGameListLength() external view returns (uint256) {
        return gameList.length;
    }

    /**
     * @notice get user owned game list
     * @param user The user address
     * @param startIdx The start index of game list
     * @param limit The limit of game list
     * @return The list of game address
     */
    function userOwnedGames(address user, uint startIdx, uint limit) external view returns (address[] memory) {
        address[] memory games = userGames[user];
        require(startIdx < games.length, "startIdx must be less than games length");
        uint endIdx = startIdx + limit;
        if (endIdx > games.length) {
            endIdx = games.length;
        }
        address[] memory list = new address[](endIdx - startIdx);
        for (uint i = startIdx; i < endIdx; i++) {
            list[i - startIdx] = games[i];
        }
        return list;
    }
}
