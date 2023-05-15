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
contract DEFYTransformLoot is Pausable, AccessControl {
    bytes32 public constant OPENER_ROLE = keccak256("OPENER_ROLE");

    // Mapping from IDEFYLoot to validity contract condition
    mapping(address => bool) private validLootContracts;

    // Event indexed by operative address
    event TransformLoot(
        address indexed operativeAddress,
        uint256[] outputLootIds,
        uint256[] outputLootAmounts,
        uint256[] inputLootIds,
        uint256[] inputLootAmounts
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Burns the input crate item
     *      Mints the output loot items
     */
    function transformLoot(
        IDEFYLoot lootContract,
        address operativeAddress,
        uint256[] calldata outputLootIds,
        uint256[] calldata outputLootAmounts,
        uint256[] calldata inputLootIds,
        uint256[] calldata inputLootAmounts
    ) public onlyRole(OPENER_ROLE) whenNotPaused {
        // require call is made to a valid loot contract
        require(
            validLootContracts[address(lootContract)],
            "DEFYTransformLoot: Loot contract not valid"
        );

        // require input and outputs are not null
        require(
            outputLootAmounts.length != 0 &&
                outputLootIds.length != 0 &&
                inputLootIds.length != 0 &&
                inputLootAmounts.length != 0,
            "DEFYTransformLoot: Invalid input loots"
        );

        // require input loots ids and amount are the same
        require(
            outputLootAmounts.length == outputLootIds.length &&
            inputLootAmounts.length == inputLootIds.length,
            "DEFYTransformLoot: All arrays must be the same length"
        );

        // require operative own has all the input tokens available
        for (uint i = 0; i < inputLootIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddress, inputLootIds[i]) >= inputLootAmounts[i],
                "DEFYTransformLoot: Operative does not own the input items"
            );
        }

        // burn crate input items
        for (uint i = 0; i < inputLootIds.length; i++) {
            lootContract.burnToken(operativeAddress, inputLootIds[i], inputLootAmounts[i]);
        }

        bytes memory zeroBytes;

        // mint output items
        lootContract.mintBatch(
            operativeAddress,
            outputLootIds,
            outputLootAmounts,
            zeroBytes
        );

        emit TransformLoot(
            operativeAddress,
            outputLootIds,
            outputLootAmounts,
            inputLootIds,
            inputLootAmounts
        );
    }

    /**
     * @dev Returns the validity of the an lootContract address.
     * @return the boolean of validity.
     */
    function getLootContractValidity(
        IDEFYLoot lootContract
    ) public view returns (bool) {
        return validLootContracts[address(lootContract)];
    }

    /**
     * @dev Approves an IDEFYLoot contract address for forging.
     */
    function approveLootContract(
        IDEFYLoot lootContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validLootContracts[address(lootContract)] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for forging.
     */
    function revokeLootContract(
        IDEFYLoot lootContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validLootContracts[address(lootContract)] = false;
    }
}
