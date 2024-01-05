// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDToken {
    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address indexed minter, uint mintAmount, uint mintTokens);
    
    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address indexed redeemer, uint redeemAmount, uint redeemTokens);
}