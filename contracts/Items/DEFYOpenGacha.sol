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

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validLootContracts;

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
    ) public onlyRole(OPENER_ROLE) {
        // require call is made to a valid loot contract
        require(
            validLootContracts[lootContract] == true,
            "DEFYOpenGacha: Loot contract not valid"
        );

        // require input and outputs are not null
        require(
            outputLootAmounts.length != 0 &&
                outputLootIds.length != 0 &&
                inputGachaItem != 0,
            "DEFYOpenGacha: Invalid input loots"
        );

        // require input loots ids and amount are the same
        require(
            outputLootAmounts.length == outputLootIds.length,
            "DEFYOpenGacha: All arrays must be the same length"
        );

        // require operative own has Gacha token available
        require(
            lootContract.balanceOf(operativeAddress, inputGachaItem) >= 1,
            "DEFYOpenGacha: Operative does not own Gacha item"
        );

        // burn gacha input item
        lootContract.burnToken(operativeAddress, inputGachaItem, 1);

        bytes memory zeroBytes;

        // mint output items
        lootContract.mintBatch(
            operativeAddress,
            outputLootIds,
            outputLootAmounts,
            zeroBytes
        );

        emit OpenGacha(
            operativeAddress,
            outputLootIds,
            outputLootAmounts,
            inputGachaItem
        );
    }

    /**
     * @dev Returns the validity of the an lootContract address.
     * @return the boolean of validity.
     */
    function getLootContractValidity(IDEFYLoot lootContract)
        public
        view
        returns (bool)
    {
        return validLootContracts[lootContract];
    }

    /**
     * @dev Approves an IDEFYLoot contract address for forging.
     */
    function approveLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for forging.
     */
    function revokeLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = false;
    }
}
