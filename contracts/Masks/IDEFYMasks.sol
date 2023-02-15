// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDEFYMasks is ERC1155 {
    // @dev Mints a new Mask and returns the tokenId
    function safeMint(address to) external returns (uint256);
}
