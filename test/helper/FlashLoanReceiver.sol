// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "../../src/interfaces/IFlashLoan.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlashLoanReceiver is Test, IFlashLoanReceiver {
    function executeOperation(
      address asset,
      uint256 amount,
      uint256 fee,
      address initiator,
      bytes calldata params
    ) external returns (bool) {
        require(IERC20(asset).balanceOf(address(this)) == amount, "flash loan amount not equal");
        uint256 repayAmount = amount + fee;
        IERC20(asset).approve(msg.sender, repayAmount);
        deal(asset, address(this), repayAmount);
        require(IERC20(asset).balanceOf(address(this)) == repayAmount, "flash loan repayAmount not equal");
        return true;
    }
}