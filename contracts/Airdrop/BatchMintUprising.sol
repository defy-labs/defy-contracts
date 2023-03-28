// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../Masks/IDEFYUprisingMask.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact michael@defylabs.xyz
contract BatchMintUprising is AccessControl {
	  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function batchMintUprising(
        IDEFYUprisingMask maskContract,
        address[] calldata addresses
    ) public onlyRole(MINTER_ROLE) {
        require(
            addresses.length <= 80,
            "BatchAirdrop: airdrop max count is 80"
        );

        bytes memory zeroBytes;

        for (uint256 i = 0; i < addresses.length; i++) {
            maskContract.mintMask(
                addresses[i]
						);
        }
    }
}
