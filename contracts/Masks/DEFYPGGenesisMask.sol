// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import "../Invites/InviteTypes.sol";
import "../Invites/IDEFYGenesisInvite.sol";

// ______ _____________   __                                                                           
// |  _  \  ___|  ___\ \ / /                                                                           
// | | | | |__ | |_   \ V /                                                                            
// | | | |  __||  _|   \ /                                                                             
// | |/ /| |___| |     | |                                                                             
// |___/ \____/\_|     \_/                                                                             
//                                                                                                                                                                        
//                                                                                                    
//       __  __                                                                                        
//       \ \/ /                                                                                        
//        >  <                                                                                         
//       /_/\_\                                                                                        
//                                                                                                    
//                                                                                               
// ______ _   _   ___   _   _ _____ ________  ___    _____   ___   _       ___  __   _______ _____ _____ 
// | ___ \ | | | / _ \ | \ | |_   _|  _  |  \/  |   |  __ \ / _ \ | |     / _ \ \ \ / /_   _|  ___/  ___|
// | |_/ / |_| |/ /_\ \|  \| | | | | | | | .  . |   | |  \// /_\ \| |    / /_\ \ \ V /  | | | |__ \ `--. 
// |  __/|  _  ||  _  || . ` | | | | | | | |\/| |   | | __ |  _  || |    |  _  | /   \  | | |  __| `--. \
// | |   | | | || | | || |\  | | | \ \_/ / |  | |   | |_\ \| | | || |____| | | |/ /^\ \_| |_| |___/\__/ /
// \_|   \_| |_/\_| |_/\_| \_/ \_/  \___/\_|  |_/    \____/\_| |_/\_____/\_| |_/\/   \/\___/\____/\____/ 
//
//   JOIN THE REVOLUTION!
                                                                                                    
                         
contract DEFYPGGenesisMask is ERC721, ERC721Enumerable, Pausable, AccessControl, Ownable, InviteTypes, ReentrancyGuard, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;

    // Roles
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TOKEN_UNLOCKER_ROLE = keccak256("TOKEN_UNLOCKER_ROLE");
    bytes32 public constant BALANCE_WITHDRAWER_ROLE = keccak256("BALANCE_WITHDRAWER_ROLE");
    
    // Counters for number of public tokens minted and DEFY admin tokens minted
    Counters.Counter private _tokenIdCounter;

    // Maximum masks to be minted on this contract
    uint256 private constant MAX_MASKS = 3000;

    // Invite series id
    uint256 private constant PHASE_ONE_PG_INVITE_SERIES = 1;

    uint256 private constant ELITE_MASK_MID_VALUE = 1000;
    uint256 private constant MID_MASK_MID_VALUE = 100;

    // ChainlinkVRF config values.  Default values set for Polygon mainnet
    VRFCoordinatorV2Interface VRFCOORDINATOR;
    LinkTokenInterface LINKTOKEN;

    uint64 public vrfSubscriptionId;
    bytes32 public vrfKeyHash = 0xd729dc84e21ae57ffb6be0053bf2b0668aa2aaf300a2a7b2ddf7dc0bb6e875a8;
    uint32 public vrfCallbackGasLimit = 100000;

    // Types of masks for the purpose of rewards
    // ELITE_MASK gets 800-1,200 ($80 - $120 worth)
    // MID_MASK gets 80-120 tokens ($8 - $12 worth)
    enum MaskType {
      ELITE_MASK,
      MID_MASK
    }

    // On-chain metadata, storing the number of bonded tokens and remaining bonded tokens
    struct DEFYGenesisMaskMetadata {
      uint256 totalBondedTokens;
      uint256 remainingBondedTokens;
    }

    // Reference to the genesis invite contract, for validating and spending invites during phase one and two
    IDEFYGenesisInvite public defyGenesisInvite;

    // Base URI for mask token uris
    string private _maskBaseURI;

    // Contract URI. This needs to be set at some point
    string private _contractURI;

    // Price (in MATIC) required to mint a mask
    uint256 public mintPrice;

    // Mapping to keep track of the number of remaining mask types
    mapping(MaskType => uint256) public _remainingMaskTypeAllocation;

    // Tracker of how many tokens have been bonded overall
    uint256 private _totalBondedTokens;
    
    // Mapping of mask id to on-chain bonded token metadata
    mapping(uint256 => DEFYGenesisMaskMetadata) private _defyGenesisMaskMetadata;

    mapping(uint256 => uint256) private _vrfRequestIdToTokenId;

    // State variables that are used to enable and disable the various minting phases via the below modifiers
    bool public phaseOneActive;

    bool public chainlinkVrfActive;

    event MaskTokensAssigned(uint256 tokenId, uint256 amount);
    event MaskTokensUnlocked(uint256 tokenId, uint256 amount);

    modifier whenPhaseOneActive() {
        require(phaseOneActive, 'DGM: Phase 1 not active');
        _;
    }

    constructor(address vrfCoordinator, address vrfLinkToken) ERC721("DEFYPGGenesisMask", "DPGM") VRFConsumerBaseV2(vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        VRFCOORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(vrfLinkToken);

        // Set up the various mask type allocations
        _remainingMaskTypeAllocation[MaskType.ELITE_MASK] = 500;
        _remainingMaskTypeAllocation[MaskType.MID_MASK] = 2000;

        // Initialise the mint price
        mintPrice = 160 ether;

        // Start the contract with all phases disabled
        phaseOneActive = false;

        // Start contract without ChainlinkVRF
        chainlinkVrfActive = false;
        
        // Initialise totalBondedTokens
        _totalBondedTokens = 0;
    }

    /// @notice Allow updating of the ChainlinkVRF parameters
    function updateChainlinkParameters(uint64 newVrfSubscriptionId, bytes32 newVrfKeyHash, uint32 newVrfCallbackGasLimit) public onlyRole(DEFAULT_ADMIN_ROLE) {
      vrfSubscriptionId = newVrfSubscriptionId;
      vrfKeyHash = newVrfKeyHash;
      vrfCallbackGasLimit = newVrfCallbackGasLimit;
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

    /// @notice Get the TokenURI for the supplied token, in the form {baseURI}{tokenId}.json
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
      require(_exists(tokenId), "DGM: URI query for nonexistent token");

      return string(abi.encodePacked(_maskBaseURI, Strings.toString(tokenId), '.json'));
    }

    /// @notice Pause the contract, preventing public minting and transfers
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @notice Unpause the contract, allowing public minting and transfers
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /// @notice Admin function to allow updating of phase one status
    function updatePhaseOneStatus(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      phaseOneActive = active;
    }

    /// @notice Admin function to determine whether ChainlinkVRF is used for randomness of token assignment
    function updateChainlinkVrfActive(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      chainlinkVrfActive = active;
    }

    /// @notice Admin function to allow updating of the mint price
    function updateMintPrice(uint256 newMintPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
      mintPrice = newMintPrice;
    }

    /// @notice Admin function to allow updating of the connected invite contract address
    function updateInviteContractAddress(address inviteContractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
      defyGenesisInvite = IDEFYGenesisInvite(inviteContractAddress);
    }

    /// @notice Public phase one mint function, allowing holders of a phase 1 invite to mint a mask
    function phaseOneInviteMint(uint256 inviteId)
      public
      payable
      whenNotPaused
      whenPhaseOneActive
      nonReentrant
    {
      require(msg.value == mintPrice, 'DGM: incorrect token amount sent to mint');

      // Get invite metadata from invite contract
      DEFYGenesisInviteMetadata memory inviteMetadata = defyGenesisInvite.getInviteMetadata(inviteId);

      require(inviteMetadata.seriesId == PHASE_ONE_PG_INVITE_SERIES, 'DGM: cannot use invite fron another series for phase 1');

      // Spend the invite. This function will revert the transaction if the invite has already been sent or does not belong to the msg sender
      defyGenesisInvite.spendInvite(inviteId, msg.sender);
      
      // Mint mask
      _mintMask(msg.sender);
    }

    /// @notice Underlying mint function that checks if there is any allocation remaining and triggers the ChainlinkVRF async function
    function _mintMask(address to) internal {
      uint256 tokenId = _tokenIdCounter.current();
      require(tokenId < (MAX_MASKS), 'DGM: all public masks minted');

      _tokenIdCounter.increment();
      _safeMint(to, tokenId);

      if (chainlinkVrfActive) {
        submitRequestForRandomness(tokenId);
      } else {
        // Get random numbers
        uint256[] memory randomNumbers = new uint256[](2);
        randomNumbers[0] = random(tokenId);
        randomNumbers[1] = random(tokenId*15231);

        assignRandomTokenAmountToMask(tokenId, randomNumbers);
      }
    }

    // Send request for randomness and store the request id against the token id being minted
    function submitRequestForRandomness(uint256 tokenId) internal {
      uint16 minimumRequestConfirmations = 3;
      uint32 numWords = 2;

      // Kick off randomness request to VRF
      uint256 vrfRequestId = VRFCOORDINATOR.requestRandomWords(
        vrfKeyHash,
        vrfSubscriptionId,
        minimumRequestConfirmations,
        vrfCallbackGasLimit,
        numWords
      );

      _vrfRequestIdToTokenId[vrfRequestId] = tokenId;
    }

    function random(uint256 seed) private view returns (uint256) {
      return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
    }

    /// @notice callback function from ChainlinkVRF that receives the onchain randomness
    function fulfillRandomWords(
      uint256 requestId,
      uint256[] memory randomWords
    ) internal override(VRFConsumerBaseV2) {
      assignRandomTokenAmountToMask(_vrfRequestIdToTokenId[requestId], randomWords);
    }

    /// @notice assign tokens to the mask using the ChainlinkVRF random words as seeds
    function assignRandomTokenAmountToMask(uint256 tokenId, uint256[] memory randomWords) internal {
      MaskType maskType;
      
      // First 300 tokens have 50% chance of an elite mask
      if (tokenId < 300) {
        bool isElite = (randomWords[0] % 2) == 0;

        if (isElite) {
          maskType = MaskType.ELITE_MASK;
        } else {
          maskType = MaskType.MID_MASK;
        }
      } else {
        uint256 totalRemainingMasks = _remainingMaskTypeAllocation[MaskType.ELITE_MASK] + _remainingMaskTypeAllocation[MaskType.MID_MASK];

        // Pick random number between 0 and total remaining masks
        uint256 selectedMaskType = randomWords[0] % totalRemainingMasks;

        // Divide remaining masks up across the values
        // Pick mask type based on the random number selected above
        maskType = selectedMaskType < _remainingMaskTypeAllocation[MaskType.ELITE_MASK] ? MaskType.ELITE_MASK : MaskType.MID_MASK;
      }

      uint256 rewardAmount;

      // Perform random swing of token value (get total swing range and subtract half to do negative amounts)
      if (maskType == MaskType.ELITE_MASK) {
        uint256 swingValue = (randomWords[1] % 401);
        rewardAmount = ELITE_MASK_MID_VALUE + swingValue - 200;
      } else {
        uint256 swingValue = (randomWords[1] % 41);
        rewardAmount = MID_MASK_MID_VALUE + swingValue - 20;
      }

      _defyGenesisMaskMetadata[tokenId].totalBondedTokens = rewardAmount;
      _defyGenesisMaskMetadata[tokenId].remainingBondedTokens = rewardAmount;

      _totalBondedTokens += rewardAmount;
      _remainingMaskTypeAllocation[maskType] -= 1;
      
      emit MaskTokensAssigned(tokenId, rewardAmount);
    }

    /// @notice Get the total assigned tokens for a mask with the provided token id
    function getTotalBondedTokensForMask(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), 'DGM: token does not exist');

      return _defyGenesisMaskMetadata[tokenId].totalBondedTokens;
    }

    /// @notice Get the total remaining bonded tokens for a mask with the provided token id
    function getRemainingBondedTokensForMask(uint256 tokenId) public view returns (uint256) {
      require(_exists(tokenId), 'DGM: token does not exist');

      return _defyGenesisMaskMetadata[tokenId].remainingBondedTokens;
    }

    /// @notice Get the total amount of tokens that have been bonded across all masks on the contract
    function getTotalBondedTokens() public view returns (uint256)
    {
      return _totalBondedTokens;
    }

    /// @notice Function to be called by backend API when bonded token emission events happen in the app
    function unlockBondedTokensFromMask(uint256 tokenId, uint256 tokenAmount) public onlyRole(TOKEN_UNLOCKER_ROLE) {
      require(_exists(tokenId), "DGM: unlocking tokens from nonexistant mask");
      require(tokenAmount < _defyGenesisMaskMetadata[tokenId].remainingBondedTokens, 'DGM: cannot unlock more tokens than remaining on mask');

      _defyGenesisMaskMetadata[tokenId].remainingBondedTokens -= tokenAmount;
    }

    // Prevent token transferring when contract is paused
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Allow contract to receive MATIC directly
    receive() external payable {}

    // Allow withdrawal of the contract's current balance to the caller's address
    function withdrawBalance() public onlyRole(BALANCE_WITHDRAWER_ROLE) {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "DGM: Withdrawal failed");
    }

    // Allow withdrawal of the contract's current balance to the caller's address
    function withdrawBalanceExceptFor(uint256 tokens) public onlyRole(BALANCE_WITHDRAWER_ROLE) {
        (bool success,) = msg.sender.call{value : address(this).balance - tokens}('');
        require(success, "DGM: Withdrawal failed");
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