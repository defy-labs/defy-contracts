// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IDEFYLoot.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
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
contract DEFYOpenPartneredCrate is Pausable, AccessControl {
    bytes32 public constant OPENER_ROLE = keccak256("OPENER_ROLE");

    // Mapping from IDEFYLoot to validity contract condition
    mapping(address => bool) private validLootContracts;

    // Mappings from partnered contracts to validity contract condition
    mapping(address => bool) private validERC721PartneredContracts;
    mapping(address => bool) private validERC1155PartneredContracts;
 
    // Event indexed by operative address and partnered contract address
    event OpenERC721PartneredCrate(
        address indexed operativeAddress,
        address indexed partneredContractAddress,
        address ownerOfERC721Address,
        uint256[] transferERC721Ids,
        uint256[] inputLootIds,
        uint256[] inputLootAmounts
    );

    // Event indexed by operative address and partnered contract address
    event OpenERC1155PartneredCrate(
        address indexed operativeAddress,
        address indexed partneredContractAddress,
        address ownerOfERC721Address,
        uint256[] transferERC1155Ids,
        uint256[] transferERC1155Amounts,
        uint256[] inputLootIds,
        uint256[] inputLootAmounts
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev For Partnered ERC721 transfers
     *      Burns the input crate item/s
     *      Transfers ERC721 of partnered contract to operative
     */
    function openCrateWithPartneredERC721(
        IDEFYLoot lootContract,
        IERC721 partneredContract,
        address ownerOfERC721Address,
        address operativeAddress,
        uint256[] calldata transferERC721Ids,
        uint256[] calldata inputLootIds,
        uint256[] calldata inputLootAmounts
    ) public onlyRole(OPENER_ROLE) whenNotPaused {
        // require call is made to a valid loot contract
        require(
            validLootContracts[address(lootContract)],
            "DEFYOpenPartneredCrate: Loot contract not valid"
        );

        // require call is made to a valid partnered contract
        require(
            validERC721PartneredContracts[address(partneredContract)],
            "DEFYOpenPartneredCrate: Partnered contract not valid"
        );

        // require inputs and transfers are not null
        require(
            transferERC721Ids.length != 0 &&
            inputLootIds.length != 0 &&
            inputLootAmounts.length != 0,
            "DEFYOpenPartneredCrate: Invalid input data"
        );

        // require input ids and amount are the same
        require(
            inputLootIds.length == inputLootAmounts.length,
            "DEFYOpenPartneredCrate: All arrays must be the same length"
        );

        // require operative has all the input tokens available
        for (uint i = 0; i < inputLootIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddress, inputLootIds[i]) >= inputLootAmounts[i],
                "DEFYOpenPartneredCrate: Operative does not own the input items"
            );
        }

        // require DEFY has all the transfer tokens available
        for (uint i = 0; i < transferERC721Ids.length; i++) {
            require(
                partneredContract.ownerOf(transferERC721Ids[i]) >= ownerOfERC721Address,
                "DEFYOpenPartneredCrate: DEFY does not own the transfer items"
            );
        }

        // burn input tokens
        for (uint i = 0; i < inputLootIds.length; i++) {
            lootContract.burnToken(operativeAddress, inputLootIds[i], inputLootAmounts[i]);
        }

        bytes memory zeroBytes;

        // transfer ERC721 tokens
        for (uint i = 0; i < transferERC721Ids.length; i++) {
            partneredContract.safeTransferFrom(ownerOfERC721Address, operativeAddress, transferERC721Ids[i], zeroBytes);
        }

        emit OpenERC721PartneredCrate(
            operativeAddress,
            address(partneredContract),
            ownerOfERC721Address,
            transferERC721Ids,
            inputLootIds,
            inputLootAmounts
        );
    }

    /**
     * @dev For Partnered ERC1155 transfers
     *      Burns the input crate item/s
     *      Transfers ERC1155 of partnered contract to operative
     */
    function openCrateWithPartneredERC1155(
        IDEFYLoot lootContract,
        IERC1155 partneredContract,
        address ownerOfERC1155Address,
        address operativeAddress,
        uint256[] calldata transferERC1155Ids,
        uint256[] calldata transferERC1155Amounts,
        uint256[] calldata inputLootIds,
        uint256[] calldata inputLootAmounts
    ) public onlyRole(OPENER_ROLE) whenNotPaused {
        // require call is made to a valid loot contract
        require(
            validLootContracts[address(lootContract)],
            "DEFYOpenPartneredCrate: Loot contract not valid"
        );

        // require call is made to a valid partnered contract
        require(
            validERC1155PartneredContracts[address(partneredContract)],
            "DEFYOpenPartneredCrate: Partnered contract not valid"
        );

        // require inputs and transfers are not null
        require(
            transferERC1155Ids.length != 0 &&
            transferERC1155Amounts.length != 0 &&
            inputLootIds.length != 0 &&
            inputLootAmounts.length != 0,
            "DEFYOpenPartneredCrate: Invalid input data"
        );

        // require input/transfer ids and amount are the same
        require(
            transferERC1155Ids.length == transferERC1155Amounts.length &&
            inputLootIds.length == inputLootAmounts.length,
            "DEFYOpenPartneredCrate: All arrays must be the same length"
        );

        // require operative has all the input tokens available
        for (uint i = 0; i < inputLootIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddress, inputLootIds[i]) >= inputLootAmounts[i],
                "DEFYOpenPartneredCrate: Operative does not own the input items"
            );
        }

        // require DEFY has all the transfer tokens availables
        for (uint i = 0; i < transferERC1155Ids.length; i++) {
            require(
                partneredContract.balanceOf(ownerOfERC1155Address, transferERC1155Ids[i]) >= transferERC1155Amounts[i],
                "DEFYOpenPartneredCrate: DEFY does not own the transfer items"
            );
        }

        // burn input tokens
        for (uint i = 0; i < inputLootIds.length; i++) {
            lootContract.burnToken(operativeAddress, inputLootIds[i], inputLootAmounts[i]);
        }

        bytes memory zeroBytes;

        // transfer ERC1155 tokens
        partneredContract.safeBatchTransferFrom(ownerOfERC1155Address, operativeAddress, transferERC1155Ids, transferERC1155Amounts, zeroBytes);

        emit OpenERC1155PartneredCrate(
            operativeAddress,
            address(partneredContract),
            ownerOfERC1155Address,
            transferERC1155Ids,
            transferERC1155Amounts,
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
        IDEFYLoot iDEFYLoot
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validLootContracts[address(iDEFYLoot)] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for forging.
     */
    function revokeLootContract(
        IDEFYLoot iDEFYLoot
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validLootContracts[address(iDEFYLoot)] = false;
    }

    /**
     * @dev Returns the validity of the an ERC721PartneredContract address.
     * @return the boolean of validity.
     */
    function getERC721PartneredContractValidity(
        IERC721 partneredContract
    ) public view returns (bool) {
        return validERC721PartneredContracts[address(partneredContract)];
    }

    /**
     * @dev Approves an ERC721PartneredContract contract address for transfering.
     */
    function approveERC721PartneredContract(
        IERC721 partneredContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validERC721PartneredContracts[address(partneredContract)] = true;
    }

    /**
     * @dev Revokes an ERC721PartneredContract contract address for transferring.
     */
    function revokeERC721PartneredContract(
        IERC721 partneredContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validERC721PartneredContracts[address(partneredContract)] = false;
    }

    /**
     * @dev Returns the validity of the an ERC1155PartneredContract address.
     * @return the boolean of validity.
     */
    function getERC1155PartneredContractValidity(
        IERC1155 partneredContract
    ) public view returns (bool) {
        return validERC1155PartneredContracts[address(partneredContract)];
    }

    /**
     * @dev Approves an ERC1155PartneredContract contract address for transfering.
     */
    function approveERC1155PartneredContract(
        IERC1155 partneredContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validERC1155PartneredContracts[address(partneredContract)] = true;
    }

    /**
     * @dev Revokes an ERC1155PartneredContract contract address for transferring.
     */
    function revokeERC1155PartneredContract(
        IERC1155 partneredContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        validERC1155PartneredContracts[address(partneredContract)] = false;
    }

}
