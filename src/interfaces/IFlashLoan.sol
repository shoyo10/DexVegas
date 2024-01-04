// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IFlashLoan {
    /**
     * @dev Emitted on flashLoan()
     * @param receiver The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param fee The fee flash borrowed
     */
    event FlashLoan(
      address indexed receiver,
      address initiator,
      address indexed asset,
      uint256 amount,
      uint256 fee
    );

    /**
     * @notice Allows smartcontracts to access the liquidity of the underlying token within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     */
    function flashLoan(
      address receiverAddress,
      uint256 amount,
      bytes calldata params
    ) external;
}

interface IFlashLoanReceiver {
    /**
     * @notice Executes an operation after receiving the flash-borrowed asset
     * @dev Ensure that the contract can return the debt + fee, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param asset The address of the flash-borrowed asset
     * @param amount The amount of the flash-borrowed asset
     * @param fee The fee of the flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
      address asset,
      uint256 amount,
      uint256 fee,
      address initiator,
      bytes calldata params
    ) external returns (bool);
}
