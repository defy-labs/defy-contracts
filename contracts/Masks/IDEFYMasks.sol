// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IDEFYMasks is IERC721 {
    /**
     * @dev Mints an ERC721 token id to the account address. Token id increments with counter.
     */
    function safeMint(address to) external;

    /**
     * @dev Burns the ERC721 of token id.
     */
    function burnMask(uint256 tokenId) external;

    /**
     * @dev Mints an ERC721 token to each account address. Token ids increment with each counter.
     */
    function safeBatchMint(address[] calldata to) external;

    /**
     * @dev Burns the ERC721 of the token ids.
     */
    function batchBurnMasks(uint256[] calldata tokenIds) external;
}
