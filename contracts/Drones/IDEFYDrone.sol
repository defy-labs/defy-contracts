// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDEFYDrone is IERC721 {
    // @dev Mints a new Drone and returns the tokenId
    function safeMint(address to) external returns (uint256);
}
