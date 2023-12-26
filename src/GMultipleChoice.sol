// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./interfaces/IGMultipleChoiceDeployer.sol";

contract GMultipleChoice is IGMultipleChoiceDeployer {
    address public immutable factory;
    address public immutable initiator;
    uint256 public immutable minAmount; 
    uint256 public immutable maxAmount;
    uint public immutable closeBetTime;
    uint public immutable lotteryDrawTime;
    uint public immutable playerUpperLimit;
    string[] public choose;
    uint public result;

    constructor(Parameters memory params) {
        factory = params.factory;
        initiator = params.initiator;
        minAmount = params.minAmount;
        maxAmount = params.maxAmount;
        closeBetTime = params.closeBetTime;
        lotteryDrawTime = params.lotteryDrawTime;
        playerUpperLimit = params.playerUpperLimit;
        choose = params.choose;
    }
}
