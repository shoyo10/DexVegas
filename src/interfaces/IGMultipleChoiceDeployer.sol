// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IGMultipleChoiceDeployer {
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
}