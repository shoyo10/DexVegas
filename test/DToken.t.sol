// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "./helper/MyERC20.sol";
import "../src/interfaces/IDToken.sol";
import { DToken } from  "../src/DToken.sol";

contract DTokenTest is Test, IDToken {
    address public user1;

    function setUp() public {
        user1 = payable(makeAddr("user1"));
    }

    function test_constructor() public {
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        DToken token = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);
        assertEq(token.name(), "DToken");
        assertEq(token.symbol(), "DTKN");
        assertEq(token.decimals(), 18);
        assertEq(token.underlyingToken(), address(underlyingToken));
        assertEq(token.admin(), address(this));
    }
    
    function test_mint_exchange_rate_1e18() public {
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        // underlyingToken 與 dToken 的 exchange rate 為 1:1
        DToken token = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);

        // user1 mints dToken by provide 10 underlying tokens
        uint mintAmount = 10 * 10 ** underlyingToken.decimals();
        deal(address(underlyingToken), user1, mintAmount);
        vm.startPrank(user1);
        underlyingToken.approve(address(token), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit Mint(user1, mintAmount, mintAmount);
        token.mint(mintAmount);
        vm.stopPrank();

        assertEq(underlyingToken.balanceOf(address(token)), mintAmount);
        assertEq(token.balanceOf(user1), mintAmount);

        uint secondMintAmount = 5 * 10 ** underlyingToken.decimals();
        deal(address(underlyingToken), user1, secondMintAmount);
        vm.startPrank(user1);
        underlyingToken.approve(address(token), secondMintAmount);
        vm.expectEmit(true, true, true, true);
        emit Mint(user1, secondMintAmount, secondMintAmount);
        token.mint(secondMintAmount);
        vm.stopPrank();

        assertEq(underlyingToken.balanceOf(address(token)), mintAmount+secondMintAmount);
        assertEq(token.balanceOf(user1), mintAmount+secondMintAmount);
        assertEq(token.totalSupply(), mintAmount+secondMintAmount);
    }

    function test_mint_exchange_rate_1e15() public {
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        // underlyingToken 與 dToken 的 exchange rate 為 1:1000
        DToken token = new DToken("DToken", "DTKN", address(underlyingToken), 1e15);

        // user1 mints dToken by provide 10 underlying tokens
        uint mintAmount = 10 * 10 ** underlyingToken.decimals();
        deal(address(underlyingToken), user1, mintAmount);
        vm.startPrank(user1);
        underlyingToken.approve(address(token), mintAmount);
        vm.expectEmit(true, true, true, true);
        emit Mint(user1, mintAmount, mintAmount*1000);
        token.mint(mintAmount);
        vm.stopPrank();

        assertEq(underlyingToken.balanceOf(address(token)), mintAmount);
        assertEq(token.balanceOf(user1), mintAmount*1000);
    }

    function test_mint_underlying_token_decimal_6() public {
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 6);
        // underlyingToken 與 dToken 的 exchange rate 為 1:1
        DToken token = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);

        // user1 mints dToken by provide 10 underlying tokens
        uint mintAmount = 10 * 10 ** underlyingToken.decimals();
        deal(address(underlyingToken), user1, mintAmount);
        vm.startPrank(user1);
        underlyingToken.approve(address(token), mintAmount);
        token.mint(mintAmount);
        vm.stopPrank();

        assertEq(underlyingToken.balanceOf(address(token)), mintAmount);
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), mintAmount);
    }
}