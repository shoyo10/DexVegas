// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract DexVegas {
    struct Game {
        string name;
        bool isSupported;
        address factory;
    }

    // supported game types
    mapping(string => Game) public supportedGames;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    function addGame(string calldata name, address factory) external {
        require(msg.sender == owner, "Only owner can add game");
        require(bytes(supportedGames[name].name).length == 0, "Game duplicated");
        supportedGames[name] = Game(name, true, factory);
    }

    function getGameByName(string calldata _name) external view returns (string memory name, bool isSupported , address factory) {
        require(bytes(supportedGames[_name].name).length > 0, "Game is not exist");
        Game memory game = supportedGames[_name];
        return (game.name, game.isSupported, game.factory);
    }
}
