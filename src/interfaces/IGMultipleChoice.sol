// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IGMultipleChoice {
    event Betting(address indexed user, uint256 indexed tokenId, uint256 amount, uint256 option);
}