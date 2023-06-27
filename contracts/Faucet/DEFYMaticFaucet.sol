// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../Items/IDEFYLoot.sol";
import "../Masks/IDEFYMasks.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

/// @custom:security-contact michael@defylabs.xyz
contract DEFYMaticFaucet is Pausable, AccessControl {
    bytes32 public constant FAUCET_ROLE = keccak256("FAUCET_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    // Faucet amount in wei
    uint256 public faucetAmount;
    IDEFYLoot public defyLoot;
    IDEFYMasks public defyMasks;
    uint256 public lootItem;

    mapping(address => bool) private _maticFaucetClaimed;

    constructor(
        IDEFYLoot lootContract,
        IDEFYMasks masksContract,
        uint256 lootItemToCheck
    ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        defyLoot = lootContract;
        defyMasks = masksContract;
        lootItem = lootItemToCheck;
    }

    // Utility functions
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAllMatic(
        address payable to
    ) external payable whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = getBalance();
        (bool success, ) = to.call{value: amount}("");
        require(success, "transaction failed");
    }

    function requestMatic(
        address payable to
    ) public payable whenNotPaused onlyRole(FAUCET_ROLE) {
        // check address is not contract address
        require(
            !Address.isContract(to),
            "DEFYMaticFaucet: Address is a contract address"
        );

        // address has 0 matic
        require(to.balance == 0, "DEFYMaticFaucet: Address already has Matic");

        // address has defyLoot
        require(
            defyLoot.balanceOf(to, lootItem) >= 1,
            "DEFYMaticFaucet: Address does not own specified item"
        );

        // address has a free mask
        require(
            defyMasks.balanceOf(to) >= 1,
            "DEFYMaticFaucet: Address does not own a mask"
        );

        // address has not claimed before
        require(
            !_maticFaucetClaimed[to],
            "DEFYMaticFaucet: Address has already claimed Matic"
        );

        // set claimed flag
        _maticFaucetClaimed[to] = true;

        // send matic to operative address
        (bool success, ) = to.call{value: faucetAmount}("");
        require(success, "transaction failed");
    }

    // set faucent amount in Wei
    function setFaucetAmount(
        uint256 amount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        faucetAmount = amount;
    }

    function setDEFYLootContract(
        IDEFYLoot defyLootContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defyLoot = defyLootContract;
    }

    function setDEFYMasksContract(
        IDEFYMasks defyMasksContract
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        defyMasks = defyMasksContract;
    }

    function setLootItem(
        uint256 lootItemTokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lootItem = lootItemTokenId;
    }

    // receives matic
    receive() external payable {}

    fallback() external payable {}
}
