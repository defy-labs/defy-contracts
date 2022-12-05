// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IDEFYLoot is IERC1155 {
    /**
     * @dev Mints an amount of ERC1155 tokens of id, to the account address.
     */
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Burns the amount of tokens of id owned by the owner account.
     */
    function burnToken(
        address owner,
        uint256 id,
        uint256 amount
    ) external;

    /**
     * @dev Mints an array of amounts of ERC1155 tokens of id, to the account address.
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /**
     * @dev Mints an amount of ERC1155 tokens of id, to the multiple addresses.
     */
    function mintBatchMultiUser(
        address[] calldata addresses,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;
}
