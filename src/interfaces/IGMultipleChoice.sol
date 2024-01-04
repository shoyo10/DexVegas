// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IGMultipleChoice {
    event Betting(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 option);
    event SetAnswer(address indexed user, uint256 answerIndex);
    event WinnerClaim(address indexed user, uint256 indexed tokenId, uint256 amount);

    enum LotteryTicketClaimed {
        NotClaimed,
        Claimed
    }
    struct LotteryTicket {
        uint256 optionIndex;
        uint256 amount;
        LotteryTicketClaimed claimStatus;
    }

    function betting(uint256 amount, uint256 optionIndex) external returns (uint256 tokenId);
    function setAnswer(uint256 index) external;
    function winnerClaimAward(uint256 tokenId) external returns (uint256 claimAmount);
    function getOptionsLength() external view returns (uint256);
    function getLotteryTicket(
        uint256 tokenId
    ) external view returns (uint256 optionIndex, uint256 amount, LotteryTicketClaimed claimStatus);
    function totalBettingAmount() external view returns (uint256);
    function totalAwardAmount() external view returns (uint256);
    function optionBettingAmount(uint256 optionIndex) external view returns (uint256);
    function answerIndex() external view returns (int256);
}
