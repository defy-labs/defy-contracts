// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IERC1155Minter.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact michael@defylabs.xyz
contract BatchAirdrop is AccessControl {
	  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() {
      _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function batchAirdrop1155(
        IERC1155 tokenContract,
        address[] calldata addresses,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public onlyRole(MINTER_ROLE) {
        require(
            addresses.length <= 80,
            "BatchAirdrop: airdrop max count is 80"
        );
        require(
            addresses.length == tokenIds.length &&
                addresses.length == amounts.length,
            "BatchAirdrop: All arrays must be the same length"
        );

        bytes memory zeroBytes;

        for (uint256 i = 0; i < addresses.length; i++) {
            tokenContract.mint(
                addresses[i],
                tokenIds[i],
                amounts[i],
                zeroBytes
            );
        }
    }
}
