// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./interfaces/IGMultipleChoiceDeployer.sol";
import "./GMultipleChoice.sol";

contract GMultipleChoiceDeployer is IGMultipleChoiceDeployer {
    function deploy(Parameters memory p_) internal returns (address gameAddress) {
        Parameters memory params = p_;
        gameAddress = address(new GMultipleChoice(params));
    }
}
