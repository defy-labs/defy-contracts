// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/// @custom:security-contact michael@defylabs.xyz
contract DEFYSwag is ERC1155, AccessControl, Pausable, Ownable {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SWAG_BURNER_ROLE = keccak256("SWAG_BURNER_ROLE");

    mapping(uint256 => bool) private _tokenTradingEnabled;
		
		mapping(address => bool) private _tradingFromAddressWhitelisted;

    constructor() ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function setURI(string memory newuri) public onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
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

    function burnToken(
        address owner,
        uint256 id,
        uint256 amount
    ) public onlyRole(SWAG_BURNER_ROLE) {
        _burn(owner, id, amount);
    }

    function setTokenTradingEnabledForToken(
        uint256 tokenId,
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenTradingEnabled[tokenId] = enabled;
    }

		function setTokenTradingWhitelistedForFromAddress(
        address whitelistedAddress,
        bool whitelisted
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tradingFromAddressWhitelisted[whitelistedAddress] = whitelisted;
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
                (_tokenTradingEnabled[ids[i]] || _tradingFromAddressWhitelisted[from]) ||
                    from == address(0) ||
                    to == address(0),
                "DEFYSwag: Token trading has not been enabled this token"
            );
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
