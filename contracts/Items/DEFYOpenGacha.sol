// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IDEFYLoot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

/// @custom:security-contact michael@defylabs.xyz
contract DEFYOpenGacha is Pausable, AccessControl {
    bytes32 public constant OPENER_ROLE = keccak256("OPENER_ROLE");

    // Event indexed by operative address
    event OpenGacha(
        address indexed operativeAddress,
        uint256[] outputLootIds,
        uint256[] outputLootAmounts,
        uint256 inputGachaItem
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Burns the input gacha item
     *      Mints the output loot items
     */
    function openGacha(
        IDEFYLoot lootContract,
        address operativeAddress,
        uint256[] calldata outputLootIds,
        uint256[] calldata outputLootAmounts,
        uint256 inputGachaItem
    ) public onlyRole(OPENER_ROLE) {}
}
