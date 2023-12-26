// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./interfaces/IGMultipleChoiceDeployer.sol";
import "./GMultipleChoice.sol";

contract GMultipleChoiceDeployer is IGMultipleChoiceDeployer {
    Parameters public parameters;
    function deploy(Parameters memory p_) internal returns (address gameAddress) {
        parameters = p_;
        gameAddress = address(new GMultipleChoice());
        delete parameters;
    }

    function getParameters() external view returns (Parameters memory) {
        return parameters;
    }
}
