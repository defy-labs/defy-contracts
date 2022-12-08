// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./IDEFYLoot.sol";

/// @custom:security-contact michael@defylabs.xyz
contract DEFYLoot is IDEFYLoot, ERC1155, AccessControl, Pausable, Ownable, DefaultOperatorFilterer {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant LOOT_BURNER_ROLE = keccak256("LOOT_BURNER_ROLE");

    mapping(uint256 => bool) private _tokenTradingDisabled;

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function setURI(string memory newUri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newUri);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        _mintBatch(to, ids, amounts, data);
    }

    function mintBatchMultiUser(
        address[] calldata addresses,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public onlyRole(MINTER_ROLE) {
        require(
            addresses.length <= 80,
            "DEFYItems: mint batch max count is 80"
        );
        require(
            addresses.length == tokenIds.length &&
                addresses.length == amounts.length,
            "DEFYItems: All arrays must be the same length"
        );

        bytes memory zeroBytes;

        for (uint256 i = 0; i < addresses.length; i++) {
            mint(addresses[i], tokenIds[i], amounts[i], zeroBytes);
        }
    }

    function burnToken(
        address owner,
        uint256 id,
        uint256 amount
    ) public onlyRole(LOOT_BURNER_ROLE) {
        _burn(owner, id, amount);
    }

    function setTokenTradingEnabledForToken(uint256 tokenId, bool disabled)
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
                !_tokenTradingDisabled[ids[i]] ||
                    from == address(0) ||
                    to == address(0),
                "DEFYLoot: Token trading has not been enabled this token"
            );
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setApprovalForAll(address operator, bool approved) 
        public 
        override(ERC1155, IERC1155) 
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
        public
        override(ERC1155, IERC1155)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override(ERC1155, IERC1155) onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
