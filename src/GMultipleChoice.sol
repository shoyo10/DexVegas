// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IGMultipleChoiceDeployer.sol";

contract GMultipleChoice {
    address public immutable factory;
    address public immutable initiator;
    uint256 public immutable minAmount; 
    uint256 public immutable maxAmount;
    uint public immutable closeBetTime;
    uint public immutable lotteryDrawTime;
    uint public immutable playerUpperLimit;
    string[] public choose;
    uint public result;

    constructor() {
        IGMultipleChoiceDeployer deployer = IGMultipleChoiceDeployer(msg.sender);
        (
            factory,
            initiator,
            minAmount,
            maxAmount,
            closeBetTime,
            lotteryDrawTime,
            playerUpperLimit,
            choose
        ) = deployer.getParameters();
    }
}
