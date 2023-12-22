// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ExponentialNoError.sol";
import "./interfaces/IDToken.sol";

contract DToken is ERC20, IDToken, ExponentialNoError {
    address public owner;
    address public underlyingToken;
    uint internal exchangeRateMantissa;

    constructor(
        string memory name_, 
        string memory symbol_,
        address underlyingToken_,
        uint exchangeRateMantissa_
    ) ERC20(name_, symbol_) {
        exchangeRateMantissa = exchangeRateMantissa_;
        owner = msg.sender;
        underlyingToken = underlyingToken_;
    }

    /**
     * @notice Sender supplies underlying tokens to get dTokens
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param mintAmount_ The amount of the underlying asset to supply
     */
    function mint(uint mintAmount_) external {
        require(mintAmount_ > 0, "mint amount must be greater than 0");
        address minter = msg.sender;
        
        uint actualMintAmount = transferIn(minter, mintAmount_);
    
        // mintTokens = actualMintAmount / exchangeRate
        Exp memory exchangeRate = Exp({mantissa: exchangeRateMantissa});
        uint mintTokens = div_(actualMintAmount, exchangeRate);
        _mint(minter, mintTokens);
        
        emit Mint(minter, actualMintAmount, mintTokens);
    }

    function transferIn(address from, uint amount) internal returns (uint) {
        IERC20 token = IERC20(underlyingToken);

        uint balanceBefore = token.balanceOf(address(this));
        (bool success) = token.transferFrom(from, address(this), amount);
        require(success, "transferFrom failed");

        uint balanceAfter = token.balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }
}
