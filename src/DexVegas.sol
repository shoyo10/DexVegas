// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IDexVegas } from "./interfaces/IDexVegas.sol";

contract DexVegas is IDexVegas {
    address public owner;
    // supported game types
    mapping(string => GameType) public supportedGameTypes;
    GameType[] internal gameTypeList;

    constructor() {
        owner = msg.sender;
    }

    /// @inheritdoc IDexVegas
    function addGameType(string calldata name, address factory) external {
        require(msg.sender == owner, "Only owner can add game");
        require(bytes(supportedGameTypes[name].name).length == 0, "Game type duplicated");
        supportedGameTypes[name] = GameType(name, factory);
        gameTypeList.push(GameType(name, factory));

        emit AddGameType(msg.sender, name, factory);
    }

    /// @inheritdoc IDexVegas
    function getGameTypeByName(string calldata _name) external view returns (string memory name, address factory) {
        require(bytes(supportedGameTypes[_name].name).length > 0, "Game type is not exist");
        GameType memory gameType = supportedGameTypes[_name];
        return (gameType.name, gameType.factory);
    }

    /// @inheritdoc IDexVegas
    function getGameTypeList(uint256 start, uint256 end) external view returns (GameType[] memory) {
        require(start < end, "Start must be less than end");
        require(end <= gameTypeList.length, "End must be less than gameTypeList length");
        GameType[] memory list = new GameType[](end - start);
        for (uint256 i = start; i < end; i++) {
            list[i - start] = gameTypeList[i];
        }
        return list;
    }

    /// @inheritdoc IDexVegas
    function getGameTypeListLength() external view returns (uint256) {
        return gameTypeList.length;
    }
}
