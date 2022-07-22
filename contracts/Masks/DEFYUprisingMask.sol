// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V / 
// | | | |  __||  _|   \ /  
// | |/ /| |___| |     | |  
// |___/ \____/\_|     \_/  
// 
// WELCOME TO THE REVOLUTION
                         
contract DEFYUprisingMask is ERC721, ERC721Enumerable, Pausable, AccessControl, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant DECAL_APPLIER = keccak256("DECAL_APPLIER");
    
    // Counters for number of public tokens minted and DEFY admin tokens minted
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _defyTokenIdCounter;

    // Maximum masks to be minted on this contract
    uint256 private constant MAX_MASKS = 10000;
    
    // Number of masks reserved for DEFY to distribute as prizes
    uint256 private constant DEFY_RESERVED_MASKS = 400;

    // Base URI for mask token uris
    string private _maskBaseURI;

    // Contract URI. This needs to be set at some point
    string private _contractURI;

    struct AppliedDecal {
      address decalContractAddress;
      uint256 tokenId;
    }

    // Mapping of mask id to applied decals in slots (up to 256 decals applied per mask)
    mapping(uint256 => mapping(uint8 => AppliedDecal)) private _appliedDecals;

    constructor() ERC721("DEFYUprisingMask", "DG2M") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    /// @notice View the contract URI. This is needed to allow automatic importing of collection metadata on OpenSea
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /// @notice Sets the contract URI.
    function setContractURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _contractURI = uri;
    }

    /// @notice Sets the base URI used for the tokens. This will be updated when new masks are uploaded to IPFS
    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _maskBaseURI = uri;
    }

    /// @notice Get the TokenURI for the supplied token, in the form {baseURI}{tokenId}
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "DG2M: URI query for nonexistent token");

      return string(abi.encodePacked(_maskBaseURI, Strings.toString(tokenId)));
    }

    /// @notice Pause the contract, preventing public minting and transfers
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing public minting and transfers
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Mint function that checks if there is any allocation remaining
    function mintMask(address to)
        public
        nonReentrant
        whenNotPaused
        onlyRole(MINTER_ROLE)
    {
      uint256 tokenId = _tokenIdCounter.current();
      require(tokenId < (MAX_MASKS - DEFY_RESERVED_MASKS), 'DG2M: all public masks minted');

      _tokenIdCounter.increment();
      _safeMint(to, tokenId);
    }

	/// @notice function to apply a decal to a mask and store the metadata onchain
    function applyDecal(uint256 maskId, address decalContractAddress, uint256 decalTokenId, uint8 maskSlotId)
        public
        onlyRole(DECAL_APPLIER)
        whenNotPaused
        nonReentrant
    {
        require(_exists(maskId), "DG2M: applying decal to nonexistant mask");
        
        _appliedDecals[maskId][maskSlotId] = AppliedDecal({
            decalContractAddress: decalContractAddress,
            tokenId: decalTokenId
        });
    }

    /// @notice View function to get the applied decal for a particular mask slot
	function getAppliedDecalForMaskSlot(uint256 maskId, uint8 maskSlotId) public view returns (AppliedDecal memory) {
		return _appliedDecals[maskId][maskSlotId];
	}

    /// @notice Admin mask minting function, allowing admins to airdrop masks for free, up to the reserved amount
    function adminMintMask(address to)
        external
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _defyTokenIdCounter.current() + (MAX_MASKS - DEFY_RESERVED_MASKS) ;
        require(tokenId >= MAX_MASKS - DEFY_RESERVED_MASKS, 'DG2M: all public masks minted');

        _defyTokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    // Prevent token transferring when contract is paused
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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