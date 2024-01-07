// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { Script } from "forge-std/Script.sol";
import "../test/helper/MyERC20.sol";
import { DToken } from  "../src/DToken.sol";
import { GMultipleChoiceFactory } from  "../src/GMultipleChoiceFactory.sol";
import "../src/DexVegas.sol";

contract DexVegasScript is Script {
    function run() public {
        uint256 privatekey = vm.envUint("P_KEY");

        vm.startBroadcast(privatekey);

        MyERC20 underlyingToken = new MyERC20("UTKN", "UTKN", 18);
        
        DToken token = new DToken("DToken", "DTKN", address(underlyingToken), 1e18);

        DexVegas vegas = new DexVegas();

        GMultipleChoiceFactory factory = new GMultipleChoiceFactory(address(token));
        string memory gameName = "multiple-choice betting game";
        vegas.addGameType(gameName, address(factory));

        vm.stopBroadcast();
    }
}