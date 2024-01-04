// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IGMultipleChoiceDeployerParameters {
    struct Parameters {
        address dToken;
        string name;
        string description;
        address factory;
        address creator;
        uint256 minAmount; 
        uint256 maxAmount;
        uint startBetTime;
        uint closeBetTime;
        uint lotteryDrawTime;
        uint256 playerUpperLimit;
        string[] options;
    }
}

interface IGMultipleChoiceDeployer is IGMultipleChoiceDeployerParameters {
    function getParameters() external view returns (Parameters memory);
}
