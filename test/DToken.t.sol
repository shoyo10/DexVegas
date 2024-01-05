// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "./helper/MyERC20.sol";
import { FlashLoanReceiver } from "./helper/FlashLoanReceiver.sol";
import "../src/interfaces/IDToken.sol";
import { DToken } from  "../src/DToken.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IFlashLoan, IFlashLoanReceiver } from "../src/interfaces/IFlashLoan.sol";

contract DTokenTest is Test, IDToken {
    address public user1;

    function setUp() public {
        user1 = makeAddr("user1");
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

    function test_flashLoan() public {
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

        require(underlyingToken.balanceOf(address(token)) == mintAmount);
        require(token.balanceOf(user1) == mintAmount);
        require(token.totalSupply() == mintAmount);
        console.log(underlyingToken.balanceOf(address(token)));

        address flashLoaner = makeAddr("flashLoaner");
        vm.startPrank(flashLoaner);
        FlashLoanReceiver receiver = new FlashLoanReceiver();
        uint256 loanAmount = 5 * 10 ** underlyingToken.decimals();
        uint256 expectFee = Math.mulDiv(loanAmount, token.flashLoanFee(), 1e6, Math.Rounding.Ceil);
        vm.expectEmit(true, true, true, true);
        emit IFlashLoan.FlashLoan(address(receiver), flashLoaner, address(underlyingToken), loanAmount, expectFee);
        token.flashLoan(address(receiver), loanAmount, "");
        vm.stopPrank();
        
        assertEq(underlyingToken.balanceOf(address(token)), mintAmount+expectFee);
        console.log(underlyingToken.balanceOf(address(token)));
    }

    function test_redeem_exchange_rate_1e18() public {
        // underlyingToken 與 dToken 的 exchange rate 為 1:1
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        DToken token = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);

        // user1 mints dToken by provide 10 underlying tokens
        uint mintAmount = 10 * 10 ** underlyingToken.decimals();
        deal(address(underlyingToken), user1, mintAmount);
        vm.startPrank(user1);
        underlyingToken.approve(address(token), mintAmount);
        token.mint(mintAmount);
        vm.stopPrank();

        require(underlyingToken.balanceOf(address(token)) == mintAmount);
        require(token.balanceOf(user1) == mintAmount);
        require(underlyingToken.balanceOf(user1) == 0);
        require(token.totalSupply() == mintAmount);

        uint redeemTokens = 6 * 10 ** token.decimals();
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit Redeem(user1, redeemTokens, redeemTokens);
        token.redeem(redeemTokens);
        vm.stopPrank();

        assertEq(underlyingToken.balanceOf(address(token)), mintAmount-redeemTokens);
        assertEq(token.balanceOf(user1), mintAmount-redeemTokens);
        assertEq(underlyingToken.balanceOf(user1), redeemTokens);
        assertEq(token.totalSupply(), mintAmount-redeemTokens);
    }

    function test_redeem_exchange_rate_1e15() public {
        // underlyingToken 與 dToken 的 exchange rate 為 1:1000
        MyERC20 underlyingToken = new MyERC20("Underlying Token", "UTKN", 18);
        DToken token = new DToken("DToken", "DTKN", address(underlyingToken), 1e15);

        // user1 mints dToken by provide 10 underlying tokens
        uint mintAmount = 10 * 10 ** underlyingToken.decimals();
        deal(address(underlyingToken), user1, mintAmount);
        vm.startPrank(user1);
        underlyingToken.approve(address(token), mintAmount);
        token.mint(mintAmount);
        vm.stopPrank();

        require(underlyingToken.balanceOf(address(token)) == mintAmount);
        require(token.balanceOf(user1) == mintAmount*1000);
        require(underlyingToken.balanceOf(user1) == 0);
        require(token.totalSupply() == mintAmount*1000);

        uint redeemTokens = 6000 * 10 ** token.decimals();
        vm.startPrank(user1);
        uint expectRedeemAmount = 6 * 10 ** underlyingToken.decimals();
        vm.expectEmit(true, true, true, true);
        emit Redeem(user1, expectRedeemAmount, redeemTokens);
        token.redeem(redeemTokens);
        vm.stopPrank();

        assertEq(underlyingToken.balanceOf(address(token)), 4 * 10 ** underlyingToken.decimals());
        assertEq(token.balanceOf(user1), 4000 * 10 ** token.decimals());
        assertEq(underlyingToken.balanceOf(user1), 6 * 10 ** underlyingToken.decimals());
        assertEq(token.totalSupply(), 4000 * 10 ** token.decimals());

        redeemTokens = 600;
        vm.startPrank(user1);
        expectRedeemAmount = 0;
        vm.expectRevert("input redeemTokens is not enough to redeem any underlying token");
        token.redeem(redeemTokens);
        vm.stopPrank();
    }
}