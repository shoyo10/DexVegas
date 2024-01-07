// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MyERC20 is ERC20 {
    uint8 public decimal;

    constructor(string memory name_, string memory symbol_, uint8 decimal_) ERC20(name_, symbol_) {
        decimal = decimal_;
    }

    function decimals() public view override returns (uint8) {
        return decimal;
    }

    function mint(uint mintAmount_) external {
        _mint(msg.sender, mintAmount_);
    }
}