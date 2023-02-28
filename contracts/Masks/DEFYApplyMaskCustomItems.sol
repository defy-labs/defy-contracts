// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../Items/IDEFYLoot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

/// @custom:security-contact michael@defylabs.xyz
contract DEFYApplyMaskCustomItems is Pausable, AccessControl {
    bytes32 public constant CUSTOMISE_MASK_ROLE =
        keccak256("CUSTOMISE_MASK_ROLE");

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validLootContracts;

    // Event indexed by operative address and forgeJobId.
    event ApplyMaskCustomisation(
        address indexed operativeAddress,
        uint256[] indexed tokenIds
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Burns the input loots.
     *      Assumes unique inputTokenIds
     */
    function applyMaskCustomisation(
        IDEFYLoot lootContract,
        address operativeAddress,
        uint256[] calldata inputTokenIds
    ) public onlyRole(CUSTOMISE_MASK_ROLE) {
        // require call is made to a valid loot contract
        require(
            validLootContracts[lootContract] == true,
            "DEFYApplyMaskCustomItems: Loot contract not valid"
        );

        // require input array is not null
        require(
            inputTokenIds.length != 0,
            "DEFYApplyMaskCustomItems: Invalid input loots"
        );

        // require operative has tokens available
        for (uint256 i = 0; i < inputTokenIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddress, inputTokenIds[i]) >= 1,
                "DEFYApplyMaskCustomItems: Operative does not have suffient loots"
            );
        }

        // burn input loots
        for (uint256 i = 0; i < inputTokenIds.length; i++) {
            lootContract.burnToken(operativeAddress, inputTokenIds[i], 1);
        }

        emit ApplyMaskCustomisation(operativeAddress, inputTokenIds);
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
