// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IDEFYLoot.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DEFYBatchBurn is AccessControl {
    bytes32 public constant LOOT_BURNER_ROLE = keccak256("LOOT_BURNER_ROLE");

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validLootContracts;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Burns the input loots.
     */
    function batchBurn(
        IDEFYLoot lootContract,
        address[] calldata operativeAddresses,
        uint256[] calldata inputLootIds,
        uint256[] calldata inputLootAmounts
    ) public onlyRole(LOOT_BURNER_ROLE) {
        // require call is made to a valid loot contract
        require(
            validLootContracts[lootContract] == true,
            "DEFYBatchBurn: Loot contract not valid"
        );

        // require input arrays are not null
        require(
            inputLootAmounts.length != 0 && inputLootIds.length != 0 && operativeAddresses.length != 0,
            "DEFYBatchBurn: Invalid input loots"
        );

        // require operative addresses, input loots ids, amount are the same
        require(
            inputLootAmounts.length == inputLootIds.length &&
            inputLootAmounts.length == operativeAddresses.length,
            "DEFYBatchBurn: All arrays must be the same length"
        );

        // require operative has tokens available
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddresses[i], inputLootIds[i]) >=
                    inputLootAmounts[i],
                "DEFYBatchBurn: Operative does not have suffient loots"
            );
        }

        // burn input loots
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            lootContract.burnToken(
                operativeAddresses[i],
                inputLootIds[i],
                inputLootAmounts[i]
            );
        }
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
