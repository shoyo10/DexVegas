// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IGMultipleChoiceDeployer.sol";
import "./GMultipleChoice.sol";

contract GMultipleChoiceDeployer is IGMultipleChoiceDeployer {
    struct Parameters {
        address factory;
        address initiator;
        uint256 minAmount; 
        uint256 maxAmount;
        uint closeBetTime;
        uint lotteryDrawTime;
        uint256 playerUpperLimit;
        string[] choose;
    }

    Parameters public parameters;

    function deploy(
        address factory,
        address initiator,
        uint256 minAmount, 
        uint256 maxAmount,
        uint closeBetTime,
        uint lotteryDrawTime,
        uint256 playerUpperLimit,
        string[] memory choose
    ) internal returns (address gameAddress) {
        parameters = Parameters(
            factory,
            initiator,
            minAmount,
            maxAmount,
            closeBetTime,
            lotteryDrawTime,
            playerUpperLimit,
            choose
        );

        gameAddress = address(new GMultipleChoice());

        delete parameters;
    }

    function getParameters() external view returns (
        address factory,
        address initiator,
        uint256 minAmount, 
        uint256 maxAmount,
        uint closeBetTime,
        uint lotteryDrawTime,
        uint256 playerUpperLimit,
        string[] memory choose
    ) {
        return (
            parameters.factory,
            parameters.initiator,
            parameters.minAmount,
            parameters.maxAmount,
            parameters.closeBetTime,
            parameters.lotteryDrawTime,
            parameters.playerUpperLimit,
            parameters.choose
        );
    }
}
