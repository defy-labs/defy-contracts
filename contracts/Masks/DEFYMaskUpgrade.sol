// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IDEFYMasks.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DEFYMaskUpgrade is Pausable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _upgradeJobIds;

    bytes32 public constant MASK_UPGRADER_ROLE =
        keccak256("MASK_UPGRADER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function upgradeMask()
        public
        onlyRole(MASK_UPGRADER_ROLE)
        returns (uint256)
    {}
}
