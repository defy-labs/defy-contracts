// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

import "./IDEFYUprisingInvite.sol";

/// @author The DEFY Labs team
/// @title DEFY Uprising Invite NFTs
contract DEFYUprisingInvite is ERC721, ERC721Enumerable, Pausable, AccessControl, Ownable, IDEFYUprisingInvite {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant INVITE_SPENDER_ROLE = keccak256("INVITE_SPENDER_ROLE");

    // Mapping from tokenId to original owner
    mapping(uint256 => address) private _tokenOriginalOwners;

    // Main token counter
    Counters.Counter private _tokenCounter;

    // Base URI. This needs to be set at some point
    string private _inviteBaseURI;

    // Contract URI. This needs to be set at some point to prefill the OpenSea collection
    string private _contractURI;

    // Event emitted when a token was successfully spent
    event InviteSpent(uint256 tokenId, address spender);

    constructor() ERC721("DEFYUprisingInvite", "DUI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Sets the base URI used for the tokens. This will be updated when new invites are uploaded to IPFS
    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _inviteBaseURI = uri;
    }

    /// @notice View the contract URI. This is needed to allow automatic importing of collection metadata on OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Sets the contract URI.
    function setContractURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = uri;
    }

    /// @notice Returns the token URI for a provided token
    /// @return Token URI in format {baseURI}
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "DEFYUprisingInvite: URI query for nonexistent token");

        return _inviteBaseURI;
    }

    /// @notice Pause the contract, preventing transfers and token spending
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing transfers and token spending
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Mint function, allowing the admin to mint a new invite
    function safeMint(address to) 
		external
		onlyRole(MINTER_ROLE)
	{
        uint256 tokenId = _tokenCounter.current();

        _tokenCounter.increment();
        
        _safeMint(to, tokenId);

		_tokenOriginalOwners[tokenId] = to;
    }

    /// @notice Mint function, allowing the admin to mint a new invite.
    function safeMint_batch(address[] memory addresses) 
		external 
		onlyRole(MINTER_ROLE)
	{
        for (uint256 i = 0; i < addresses.length; i++) {
            uint256 tokenId = _tokenCounter.current();

            _safeMint(addresses[i], tokenId);
			
			_tokenOriginalOwners[tokenId] = addresses[i];

            _tokenCounter.increment();
        }
    }

    /// @notice Require that invite is active to transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Spend the invite specified.
    function spendInvite (uint256 tokenId, address spender) 
		public
		whenNotPaused
		onlyRole(INVITE_SPENDER_ROLE)
		override(IDEFYUprisingInvite)
	{
        // Require the spender of the invite to be the current owner. We can trust the spender passed here as only the INVITE_SPENDER can call this function,
        require(spender == ownerOf(tokenId), 'DEFYUprisingInvite: address does not own invite');

		// Burn the invite, preventing it being sold again
        _burn(tokenId);
		
        emit InviteSpent(tokenId, spender);
    }

    /// @notice Get the invite metadata for the specified tokenId
    function getOriginalOwner (uint256 tokenId)
		public
		view
		override(IDEFYUprisingInvite) 
		returns (address)
	{
        require(_exists(tokenId), "DEFYUprisingInvite: metadata query for nonexistent token");
        return _tokenOriginalOwners[tokenId];
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
