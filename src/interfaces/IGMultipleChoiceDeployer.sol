// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IGMultipleChoiceParameters {
    struct Parameters {
        address dToken;
        string name;
        string description;
        address factory;
        address initiator;
        uint256 minAmount; 
        uint256 maxAmount;
        uint startBetTime;
        uint closeBetTime;
        uint lotteryDrawTime;
        uint256 playerUpperLimit;
        string[] options;
    }
}

interface IGMultipleChoiceDeployer is IGMultipleChoiceParameters {
    function getParameters() external view returns (Parameters memory);
}
