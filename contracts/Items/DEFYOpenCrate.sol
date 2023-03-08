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
contract DEFYOpenCrate is Pausable, AccessControl {
    bytes32 public constant OPENER_ROLE = keccak256("OPENER_ROLE");

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validLootContracts;

    // Event indexed by operative address
    event OpenCrate(
        address indexed operativeAddress,
        uint256[] outputLootIds,
        uint256[] outputLootAmounts,
        uint256 inputCrateItem
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Burns the input crate item
     *      Mints the output loot items
     */
    function openCrate(
        IDEFYLoot lootContract,
        address operativeAddress,
        uint256[] calldata outputLootIds,
        uint256[] calldata outputLootAmounts,
        uint256 inputCrateItem
    ) public onlyRole(OPENER_ROLE) {
        // require call is made to a valid loot contract
        require(
            validLootContracts[lootContract] == true,
            "DEFYOpenCrate: Loot contract not valid"
        );

        // require input and outputs are not null
        require(
            outputLootAmounts.length != 0 &&
                outputLootIds.length != 0 &&
                inputCrateItem != 0,
            "DEFYOpenCrate: Invalid input loots"
        );

        // require input loots ids and amount are the same
        require(
            outputLootAmounts.length == outputLootIds.length,
            "DEFYOpenCrate: All arrays must be the same length"
        );

        // require operative own has Crate token available
        require(
            lootContract.balanceOf(operativeAddress, inputCrateItem) >= 1,
            "DEFYOpenCrate: Operative does not own Crate item"
        );

        // burn crate input item
        lootContract.burnToken(operativeAddress, inputCrateItem, 1);

        bytes memory zeroBytes;

        // mint output items
        lootContract.mintBatch(
            operativeAddress,
            outputLootIds,
            outputLootAmounts,
            zeroBytes
        );

        emit OpenCrate(
            operativeAddress,
            outputLootIds,
            outputLootAmounts,
            inputCrateItem
        );
    }

    /**
     * @dev Returns the validity of the an lootContract address.
     * @return the boolean of validity.
     */
    function getLootContractValidity(
        IDEFYLoot lootContract
    ) public view returns (bool) {
        return validLootContracts[lootContract];
    }

    /**
     * @dev Approves an IDEFYLoot contract address for forging.
     */
    function approveLootContract(
        IDEFYLoot iDEFYLoot
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validLootContracts[iDEFYLoot] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for forging.
     */
    function revokeLootContract(
        IDEFYLoot iDEFYLoot
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validLootContracts[iDEFYLoot] = false;
    }
}
