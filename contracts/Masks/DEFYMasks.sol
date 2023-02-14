// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

// Reading our smart contract hey?  There's a hidden message somewhere on this contract, see if you can find it... ;)

contract DEFYMasks is
    ERC1155,
    AccessControl,
    Pausable,
    ERC1155Burnable,
    DefaultOperatorFilterer
{
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Soulbound Definition
    mapping(uint256 => bool) private _tokenTradingDisabled;

    // Counter for NFT masks
    Counters.Counter private _nftMaskIdCounter;

    // Non-Fungible base
    uint256 private constant NON_FUNGIBLE_BASE = 1000;

    // Fungible Token Ids 0-999
    // Non-Fungible Token Ids 1,000+

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // Mint Fungible Masks Only
    function mintFungibleMask(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        // Require tokenIds range to be 0-999
        require(id < 1000, "DEFYMask: Id is not for a fungible mask");

        _mint(account, id, amount, data);
    }

    // Mint Batch Fungible Masks Only
    function mintBatchFungibleMasks(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        // Require tokenIds range to be 0-999
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < 1000, "DEFYMask: Id is not for a fungible mask");
        }
        _mintBatch(to, ids, amounts, data);
    }

    function mintBatchMultiUserFungibleMasks(
        address[] calldata addresses,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) public onlyRole(MINTER_ROLE) {
        require(addresses.length <= 80, "DEFYMask: Mint batch max count is 80");
        require(
            addresses.length == ids.length &&
                addresses.length == amounts.length,
            "DEFYMask: All arrays must be the same length"
        );

        // Require tokenIds range to be 0-999
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < 1000, "DEFYMask: Id is not for a fungible mask");
        }

        bytes memory zeroBytes;

        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(addresses[i], ids[i], amounts[i], zeroBytes);
        }
    }

    // Mint NFT Masks Only
    function mintNFTMask(address account) public onlyRole(MINTER_ROLE) {
        // Get new Id from counter
        uint256 maskId = _nftMaskIdCounter.current() + NON_FUNGIBLE_BASE;
        _nftMaskIdCounter.increment();

        require(maskId >= 1000, "DEFYMask: Internal counter error");

        bytes memory zeroBytes;

        _mint(account, maskId, 1, zeroBytes);
    }

    // Burn Masks
    function burnMask(
        address from,
        uint256 id,
        uint256 amount
    ) public onlyRole(BURNER_ROLE) {
        _burn(from, id, amount);
    }

    // Burns Fungible Masks Only
    function burnBatchMask(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyRole(BURNER_ROLE) {
        _burnBatch(from, ids, amounts);
    }

    function setTokenTradingDisabledForToken(uint256 tokenId, bool disabled)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _tokenTradingDisabled[tokenId] = disabled;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        for (uint256 i = 0; i < ids.length; i++) {
            require(
                !_tokenTradingDisabled[i],
                "DEFYMasks: Token trading has been disabled for this mask"
            );
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // Utility Functions

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
