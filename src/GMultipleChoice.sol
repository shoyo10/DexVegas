// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IGMultipleChoiceDeployerParameters, IGMultipleChoiceDeployer } from "./interfaces/IGMultipleChoiceDeployer.sol";
import "./interfaces/IGMultipleChoice.sol";
import "./DToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

contract GMultipleChoice is ERC721, IGMultipleChoice, IGMultipleChoiceDeployerParameters {
    uint256 private constant BASE = 1e18;

    /// @dev The token ID lottery ticket data
    mapping(uint256 => LotteryTicket) private _lotteryTickets;

    string public gameName;
    string public gameDescription;
    address public immutable factory;
    address public immutable creator;
    uint256 public immutable minAmount; 
    uint256 public immutable maxAmount;

    /// @notice after startBetTime, user can bet the game
    uint public immutable startBetTime;

    /// @notice after closeBetTime, no one can bet the game
    uint public immutable closeBetTime;
    
    /// @notice after lotteryDrawTime, game creator can set answer index
    uint public immutable lotteryDrawTime;
    uint public immutable playerUpperLimit;
    string[] public options;
    address public dToken;

    /// @notice The index of the answer
    /// @dev The index of the answer; -1 if there is no answer yet
    int public answerIndex = -1;

    /// @dev The ID of the next token that will be minted. Skips 0
    uint256 private _nextId = 1;

    /// @notice The total amount of DToken that user bet
    uint256 public totalBettingAmount;
    /// @notice The total amount of DToken that user can claim
    /// @dev totalAwardAmount = totalBettingAmount * (1 - contract_fee - creator_fee)
    uint256 public totalAwardAmount;

    uint256 public contractFee = 1e15;
    uint256 public creatorFee = 5e15;

    /// @notice The total amount of DToken that user bet on each option
    mapping(uint256 => uint256) public optionBettingAmount;

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
        bool ok;
       (ok, totalBettingAmount) = Math.tryAdd(totalBettingAmount, amount);
       require(ok, "totalBettingAmount overflow");

        optionBettingAmount[optionIndex] = optionBettingAmount[optionIndex]+amount;
        
        // transfer buyer betting amount to this contract
        token.transferFrom(buyer, address(this), amount);
        // mint a NFT to buyer
        tokenId = _nextId;
        _nextId++;
        _safeMint(buyer, tokenId);

        _lotteryTickets[tokenId] = LotteryTicket({
            optionIndex: optionIndex,
            amount: amount,
            claimStatus: LotteryTicketClaimed.NotClaimed
        });

        emit Betting(buyer, tokenId, amount, optionIndex);
    }

    /** 
     * @notice game creator can set answer after lotteryDrawTime
     * @dev game creator can set answer index after lotteryDrawTime and 
     * transfer contract fee to multiple choice factory and transfer creator fee to creator
     * @param index The index of option to be answer
     */
    function setAnswer(uint256 index) external {
        require(msg.sender == creator, "only creator can set answer index");
        require(answerIndex == -1, "answer index has been set");
        require(index >= 0 && index < options.length, "answer index is invalid");
        require(lotteryDrawTime <= getBlockTimestamp(), "lottery draw time is not reached");

        answerIndex = int(index);

        if (totalBettingAmount > 0) {
            DToken token = DToken(dToken);
            // tranfer contract fee to multiple choice factory
            uint256 contractFeeAmount = totalBettingAmount * contractFee / BASE;
            if (contractFeeAmount > 0) {
                token.transfer(factory, contractFeeAmount);
            }
            // transfer creator fee to creator
            uint256 creatorFeeAmount = totalBettingAmount * creatorFee / BASE;
            if (creatorFeeAmount > 0) {
                token.transfer(creator, creatorFeeAmount);
            }
            // update totalAwardAmount
            totalAwardAmount = totalBettingAmount - contractFeeAmount - creatorFeeAmount;
        }

        emit SetAnswer(msg.sender, index);
    }

    /**
     * @notice winner can claim prize token
     * @dev winner can claim prize token once after answer was set
     * @param tokenId The id of NFT
     * @return claimAmount The amount of prize token
     */
    function winnerClaimAward(uint256 tokenId) external returns (uint256 claimAmount) {
        require(answerIndex >= 0, "answer index is not set");
        require(ownerOf(tokenId) == msg.sender, "only NFT owner can claim");
        LotteryTicket memory ticket = _lotteryTickets[tokenId];
        require(ticket.optionIndex == uint256(answerIndex), "only winner can claim");
        require(ticket.claimStatus == LotteryTicketClaimed.NotClaimed, "ticket has been claimed");

        _lotteryTickets[tokenId].claimStatus = LotteryTicketClaimed.Claimed;
        DToken token = DToken(dToken);
        claimAmount = totalAwardAmount * ticket.amount / optionBettingAmount[ticket.optionIndex];
        token.transfer(msg.sender, claimAmount);

        emit WinnerClaim(msg.sender, tokenId, claimAmount);
    }

    function getBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    function getOptionsLength() external view returns (uint256) {
        return options.length;
    }

    function getLotteryTicket(uint256 tokenId) external view 
        returns (
            uint256 optionIndex,
            uint256 amount,
            LotteryTicketClaimed claimStatus
        ) 
    {
        LotteryTicket memory ticket = _lotteryTickets[tokenId];
        return (ticket.optionIndex, ticket.amount, ticket.claimStatus);
    }
}
