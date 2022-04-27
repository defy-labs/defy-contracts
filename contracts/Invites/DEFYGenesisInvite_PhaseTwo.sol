// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 

import "./IDEFYGenesisInvite.sol";

/// @author The DEFY Labs team
/// @title DEFY Genesis Invite NFTs
contract DEFYGenesisInvitePhaseTwo is ERC721, ERC721Enumerable, Pausable, AccessControl, Ownable, IDEFYGenesisInvite {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant INVITE_SPENDER_ROLE = keccak256("INVITE_SPENDER_ROLE");

    // Offset for token ids for each series
    uint32 private constant SERIES_OFFSET = 100000;

    // Mapping from tokenId to on-chain metadata
    mapping(uint256 => DEFYGenesisInviteMetadata) private _tokenMetadata;

    // Main token counter
    mapping(uint8 => Counters.Counter) private _tokenSeriesIdCounters;

    // Base URI. This needs to be set at some point
    string private _inviteBaseURI;

    // Contract URI. This needs to be set at some point
    string private _contractURI;

    // Event emitted when a token was successfully spent
    event InviteSpent(uint256 tokenId, address owner);

    constructor() ERC721("DEFYGenesisInvitePhaseTwo", "DGI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
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
    /// @return Token URI in format {baseURI}/{tokenId}{_spent?}.json
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "DEFYGenesisInvite: URI query for nonexistent token");
        require(_tokenMetadata[tokenId].originalOwner != address(0), "DEFYGenesisInvite: token is missing required metadata");

        return _tokenMetadata[tokenId].inviteState == InviteState.SPENT ?
            string(abi.encodePacked(_inviteBaseURI, '_spent.json')) :
            string(abi.encodePacked(_inviteBaseURI, '.json'));
    }

    /// @notice Pause the contract, preventing transfers and token spending
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing transfers and token spending
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice default mint function that mints a new invite for the default series
    function safeMint(address to) public onlyRole(MINTER_ROLE) {
        uint8 DEFAULT_SERIES = 0;
        
        safeMint(to, DEFAULT_SERIES);
    }

    /// @notice Mint function, allowing the admin to mint a new invite. tokenId is offset by series id * SERIES_OFFSET to prevent overlap
    function safeMint(address to, uint8 seriesId) public onlyRole(MINTER_ROLE) {
        require(_tokenSeriesIdCounters[seriesId].current() < SERIES_OFFSET, 'DEFYGenesisInvite: series allocation has been exhausted');
        
        uint256 tokenId = _tokenSeriesIdCounters[seriesId].current() + (seriesId * SERIES_OFFSET);

        _tokenSeriesIdCounters[seriesId].increment();
        
        _safeMint(to, tokenId);
        
        _tokenMetadata[tokenId] = DEFYGenesisInviteMetadata({
            originalOwner: to,
            inviteState: InviteState.ACTIVE,
            seriesId: seriesId
        });
    }

    /// @notice Mint function, allowing the admin to mint a new invite. tokenId is offset by series id * SERIES_OFFSET to prevent overlap
    function safeMint_batch(address[] memory addresses , uint8 seriesId) public onlyRole(MINTER_ROLE) {
        require(_tokenSeriesIdCounters[seriesId].current() + addresses.length < SERIES_OFFSET, 'DEFYGenesisInvite: minting too many invites for this series allocation');
        
        for (uint256 i = 0; i < addresses.length; i++) {

            uint256 tokenId = _tokenSeriesIdCounters[seriesId].current() + (seriesId * SERIES_OFFSET);

            _safeMint(addresses[i], tokenId);
            
            _tokenMetadata[tokenId] = DEFYGenesisInviteMetadata({
                originalOwner: addresses[i],
                inviteState: InviteState.ACTIVE,
                seriesId: seriesId
            });

            _tokenSeriesIdCounters[seriesId].increment();
        }
    }

    /// @notice Require that invite is active to transfer
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        require(_tokenMetadata[tokenId].inviteState != InviteState.SPENT, 'DEFYGenesisInvite: spent invites cannot be transferred');
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Spend the invite specified.
    function spendInvite (uint256 tokenId, address spender) public whenNotPaused onlyRole(INVITE_SPENDER_ROLE) override(IDEFYGenesisInvite) {
        // Require the invite to not already be spent
        require(_tokenMetadata[tokenId].inviteState == InviteState.ACTIVE, 'DEFYGenesisInvite: invite was already spent');

        // Require the spender of the invite to be the current owner. We can trust the spender passed here as only the INVITE_SPENDER can call this function,
        // which is the mask smart contract
        require(spender == ownerOf(tokenId), 'DEFYGenesisInvite: address does not own invite');

        // Update the invite state to spent
        _tokenMetadata[tokenId].inviteState = InviteState.SPENT;

        emit InviteSpent(tokenId, spender);    
    }

    /// @notice Get the invite metadata for the specified tokenId
    function getInviteMetadata (uint256 tokenId) public view override(IDEFYGenesisInvite) returns (DEFYGenesisInviteMetadata memory) {
        require(_exists(tokenId), "DEFYGenesisInvite: metadata query for nonexistent token");
        return _tokenMetadata[tokenId];
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
