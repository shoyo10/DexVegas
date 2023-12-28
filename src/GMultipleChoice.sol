// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IGMultipleChoiceDeployerParameters, IGMultipleChoiceDeployer } from "./interfaces/IGMultipleChoiceDeployer.sol";
import "./interfaces/IGMultipleChoice.sol";
import "./DToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GMultipleChoice is ERC721, IGMultipleChoice, IGMultipleChoiceDeployerParameters {
    struct LotteryTicket {
        uint256 optionIndex;
        uint256 amount;
    }

    /// @dev The token ID lottery ticket data
    mapping(uint256 => LotteryTicket) private _lotteryTickets;

    string public gameName;
    string public gameDescription;
    address public immutable factory;
    address public immutable creator;
    uint256 public immutable minAmount; 
    uint256 public immutable maxAmount;
    uint public immutable startBetTime;
    uint public immutable closeBetTime;
    uint public immutable lotteryDrawTime;
    uint public immutable playerUpperLimit;
    string[] public options;
    address public dToken;

    /// @notice The index of the answer
    /// @dev The index of the answer; -1 if there is no answer yet
    int public answerIndex = -1;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint256 private _nextId = 1;

    constructor() ERC721("GMultipleChoice", "GMC") {
        Parameters memory params = IGMultipleChoiceDeployer(msg.sender).getParameters();
        require(bytes(params.name).length > 0, "name cannot be empty");
        require(params.closeBetTime > params.startBetTime, "closeBetTime must be greater than startBetTime");
        require(params.closeBetTime > block.timestamp, "closeBetTime must be greater than now");
        require(params.lotteryDrawTime > params.closeBetTime, "lotteryDrawTime must be greater than closeBetTime");
        require(params.options.length > 1, "options length must be greater than 1");
        require(params.maxAmount >= params.minAmount, "maxAmount must be greater or equal minAmount");
        dToken = params.dToken;
        gameName = params.name;
        gameDescription = params.description;
        factory = params.factory;
        creator = params.creator;
        minAmount = params.minAmount;
        maxAmount = params.maxAmount;
        startBetTime = params.startBetTime;
        closeBetTime = params.closeBetTime;
        lotteryDrawTime = params.lotteryDrawTime;
        playerUpperLimit = params.playerUpperLimit;
        options = params.options;
    }

    /**
     * @notice user can make a bet to the game multiple times and get a NFT for each betting
     * @dev user provide DToken and make a choice to bet the game and get a NFT
     * @param amount The amount of DToken to bet
     * @param optionIndex The index of option to bet
     * @return tokenId The id of NFT
     */
    function betting(uint256 amount, uint256 optionIndex) external returns (uint256 tokenId) {
        uint time = getBlockTimestamp();
        DToken token = DToken(dToken);
        address buyer = msg.sender;
        
        require(time >= startBetTime, "game is not started");
        require(time < closeBetTime, "game is closed");
        require(token.balanceOf(buyer) >= amount, "buyer has not enough DToken");
        require(optionIndex < options.length, "optionIndex is invalid");
        require(amount > 0 && amount >= minAmount, "betting amount is invalid");
        if (maxAmount > 0) {
            require(amount <= maxAmount, "betting amount is invalid");
        }
        require(_nextId  <= playerUpperLimit, "game player upper limit reached");
        // transfer buyer betting amount to this contract
        token.transferFrom(buyer, address(this), amount);
        // mint a NFT to buyer
        tokenId = _nextId;
        _nextId++;
        _safeMint(buyer, tokenId);

        _lotteryTickets[tokenId] = LotteryTicket({
            optionIndex: optionIndex,
            amount: amount
        });

        emit Betting(buyer, tokenId, amount, optionIndex);
    }

    // TODO: game owner can set result

    // TODO: user claim award

    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function getOptionsLength() external view returns (uint256) {
        return options.length;
    }
}
