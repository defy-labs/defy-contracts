// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./IDEFYMasks.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

contract DEFYMasks is
    IDEFYMasks,
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    AccessControl,
    DefaultOperatorFilterer
{
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    // Permits an address to transfer below 1 mask
    mapping(address => bool) private _tokenTradingEnabled;

    Counters.Counter private _tokenIdCounter;

    // Base URI for mask token uris
    string private _maskBaseURI;

    constructor() ERC721("DEFYMasks", "DM") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /// @notice Sets the base URI used for the tokens.
    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maskBaseURI = uri;
    }

    /// @notice Get the TokenURI for the supplied token, in the form {baseURI}{tokenId}
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "DEFYMasks: URI query for nonexistent token");

        return
            string(
                abi.encodePacked(
                    _maskBaseURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }

    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function safeBatchMint(address[] calldata to) public onlyRole(MINTER_ROLE) {
        require(to.length <= 80, "DEFYMasks: mint batch max count is 80");

        for (uint256 i = 0; i < to.length; i++) {
            safeMint(to[i]);
        }
    }

    function burnMask(uint256 tokenId) public onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function batchBurnMasks(uint256[] calldata tokenIds)
        public
        onlyRole(BURNER_ROLE)
    {
        require(tokenIds.length <= 80, "DEFYMasks: mint batch max count is 80");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    // Checks for token transfers and burns that either:
    //  Admin enabled trading for operative address; or,
    //  Operative Address will have at least 1 mask after transfer
    // If check to allow minting to bypass check
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        if (from != address(0)) {
            require(
                _tokenTradingEnabled[from] || balanceOf(from) >= 2,
                "DEFYMasks: Token trading is not enabled"
            );
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Disables token trading after transfer event
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) whenNotPaused {
        _tokenTradingEnabled[from] = false;
        super._afterTokenTransfer(from, to, tokenId);
    }

    function setTokenTradingEnabledForToken(
        address operativeAddress,
        bool enabled
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenTradingEnabled[operativeAddress] = enabled;
    }

    // Utility Functions

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Operator Filter Registry

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
