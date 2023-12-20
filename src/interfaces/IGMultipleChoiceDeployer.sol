// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IGMultipleChoiceDeployer {
    /// @notice Get the parameters to be used in constructing the game, set transiently during game creation.
    /// @dev Called by the game constructor to fetch the parameters of the game.
    function getParameters() external view returns (
        address factory,
        address initiator,
        uint256 minAmount, 
        uint256 maxAmount,
        uint closeBetTime,
        uint lotteryDrawTime,
        uint256 playerUpperLimit,
        string[] memory choose
    );
}