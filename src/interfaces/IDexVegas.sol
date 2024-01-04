// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IDexVegas {
    event AddGameType(address indexed owner, string name, address factory);

    struct GameType {
        string name;
        address factory;
    }

    /**
     * @notice Add new game type
     * @param name Game type name
     * @param factory Game type factory address
     */
    function addGameType(string calldata name, address factory) external;

    /**
     * @notice Get game type by name
     * @param _name Game type name
     * @return name and factory address of the game type
     */
    function getGameTypeByName(string calldata _name) external view returns (string memory name, address factory);

    /**
     * @notice Get game type list
     * @param start Start index
     * @param end End index
     * @return Game type list
     */
    function getGameTypeList(uint256 start, uint256 end) external view returns (GameType[] memory);

    /**
     * @notice Get game type list length
     * @return Game type list length
     */
    function getGameTypeListLength() external view returns (uint256);
}