// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ExponentialNoError.sol";
import "./interfaces/IDToken.sol";
import "./interfaces/EIP20NonStandardInterface.sol";

contract DToken is ERC20, IDToken, ExponentialNoError, ReentrancyGuard {
    address public admin;
    address public underlyingToken;
    uint internal exchangeRateMantissa;

    /**
     * @notice Initialize the game token
     * @param name_ ERC-20 name of this token
     * @param symbol_ ERC-20 symbol of this token
     * @param underlyingToken_ The address of the underlying asset
     * @param exchangeRateMantissa_ The exchange rate, scaled by 1e18
     */
    constructor(
        string memory name_, 
        string memory symbol_,
        address underlyingToken_,
        uint exchangeRateMantissa_
    ) ERC20(name_, symbol_) {
        exchangeRateMantissa = exchangeRateMantissa_;
        admin = msg.sender;
        underlyingToken = underlyingToken_;
    }

    /**
     * @notice Sender provides underlying tokens to get dTokens
     * @param mintAmount_ The amount of the underlying asset to exchange for dTokens
     */
    function mint(uint mintAmount_) external nonReentrant {
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
        address underlying_ = underlyingToken;
        EIP20NonStandardInterface token = EIP20NonStandardInterface(underlying_);
        uint balanceBefore = IERC20(underlying_).balanceOf(address(this));
        token.transferFrom(from, address(this), amount);
        
        bool success;
        assembly {
            switch returndatasize()
                case 0 {                       // This is a non-standard ERC-20
                    success := not(0)          // set success to true
                }
                case 32 {                      // This is a compliant ERC-20
                    returndatacopy(0, 0, 32)
                    success := mload(0)        // Set `success = returndata` of override external call
                }
                default {                      // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");

        // Calculate the amount that was actually transferred
        uint balanceAfter = IERC20(underlying_).balanceOf(address(this));
        return balanceAfter - balanceBefore;
    }
}
