// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../Invites/IDEFYUprisingInvite.sol";
import "../Masks/IDEFYUprisingMask.sol";

/// @custom:security-contact michael@defylabs.xyz
contract DEFYUprisingSalePhaseTwo is Pausable, AccessControl {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant APP_MINTER_ROLE = keccak256("APP_MINTER_ROLE");

    mapping(uint256 => Counters.Counter) private mintWindowCounters;
    mapping(uint256 => Counters.Counter) private mintWindowInviteCounters;

    uint256 public mintStartTime;
    uint256 public mintWindowSizeSeconds = 12 hours;
    uint256 public availableMasksPerWindow = 50;
    uint256 public availableInviteMasksPerWindow = 20;
    uint256 public mintWindowOffset = 0;

    uint256 public mintPriceInDefy = 3000 ether;

    /**
     * Receiver address for all token transfers.
     */
    address public receiver;

    IERC20 public defyToken;
    IDEFYUprisingInvite public defyUprisingInvite;
    IDEFYUprisingMask public defyUprisingMask;

    /**
     * Emitted when a setter was executed
     */
    event SetterCalled(address indexed sender, string indexed setterName);

    constructor(
        uint256 _mintStartTime, 
        address _receiver,
        IERC20 _defyToken,
        IDEFYUprisingInvite _defyUprisingInvite, 
        IDEFYUprisingMask _defyUprisingMask
    )
    {
        require(
            _receiver != address(0),
            "DEFYUprisingSalePhaseTwo: _receiver is a zero address"
        );

        require(
            address(_defyToken) != address(0),
            "DEFYUprisingSalePhaseTwo: _defyToken is a zero address"
        );
        
        require(
            address(_defyUprisingInvite) != address(0),
            "DEFYUprisingSalePhaseTwo: _defyUprisingInvite is a zero address"
        );

        require(
            address(_defyUprisingMask) != address(0),
            "DEFYUprisingSalePhaseTwo: _defyUprisingMask is a zero address"
        );

        mintStartTime = _mintStartTime;
        receiver = _receiver;
        defyToken = _defyToken;
        defyUprisingInvite = _defyUprisingInvite;
        defyUprisingMask = _defyUprisingMask;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * Pauses the contract, preventing the minting of new masks
     *
     * Access: Pauser role
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * Unpauses the contract, allowing the minting of new masks
     *
     * Access: Pauser role
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * Sets the mint start time as a utc date stamp
     *
     * Access: Admin role
     *
     * @param newMintStartTime the new start time of the mint for windows to be calculated from
     */
    function setMintStartTime(uint256 newMintStartTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintStartTime = newMintStartTime;
        emit SetterCalled(msg.sender, "setMintStartTime");
    }

    /**
     * Sets the length of each mint window in seconds
     *
     * Access: Admin role
     *
     * @param newMintWindowSizeSeconds the numer of seconds in each unique mint window
     */
    function setMintWindowSize(uint256 newMintWindowSizeSeconds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintWindowSizeSeconds = newMintWindowSizeSeconds;
        emit SetterCalled(msg.sender, "setMintWindowSize");
    }

    /**
     * Sets the offset for the mint window ids.  This is there so that when adjusting mint window sizes shorter
     * we don't end up with overlapping mint window ids, as they are derived from the current state values
     *
     * Access: Admin role
     *
     * @param newMintWindowOffset the new window offset. This should be the current window id at the time the window size is changed
     */
    function setMintWindowOffset(uint256 newMintWindowOffset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintWindowOffset = newMintWindowOffset;
        emit SetterCalled(msg.sender, "setMintWindowOffset");
    }

    /**
     * Sets the number of available publicly mintable masks per mint window
     *
     * Access: Admin role
     *
     * @param newAvailableMasksPerWindow the new number of masks per window
     */
    function setAvailableMasksPerWindow(uint256 newAvailableMasksPerWindow) external onlyRole(DEFAULT_ADMIN_ROLE) {
        availableMasksPerWindow = newAvailableMasksPerWindow;
        emit SetterCalled(msg.sender, "setAvailableMasksPerWindow");
    }
    
    /**
     * Sets the number of additional masks available to invote holders per mint window
     *
     * Access: Admin role
     *
     * @param newAvailableInviteMasksPerWindow the new number of invite masks per window
     */
    function setAvailableInviteMasksPerWindow(uint256 newAvailableInviteMasksPerWindow) external onlyRole(DEFAULT_ADMIN_ROLE) {
        availableInviteMasksPerWindow = newAvailableInviteMasksPerWindow;
        emit SetterCalled(msg.sender, "setAvailableInviteMasksPerWindow");
    }

    /**
     * Sets the mint price in $DEFY tokens of the masks
     *
     * Access: Admin role
     *
     * @param newMintPrice the new mint price in $DEFY
     */
    function setMintPriceInDefy(uint256 newMintPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintPriceInDefy = newMintPrice;
        emit SetterCalled(msg.sender, "setMintPriceInDefy");
    }

    /**
     * Sets the receiving address of the ERC20 mint transfers.
     *
     * Access: Admin role
     *
     * @param _receiver receiver of the ERC20 tokens
     */
    function setReceiver(address _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            _receiver != address(0),
            "DEFYUprisingSalePhaseTwo: _receiver is a zero address"
        );
        receiver = _receiver;
        emit SetterCalled(msg.sender, "setReceiver");
    }

    /**
     * Mints an amount of uprising masks by spending $DEFY tokens
     * If the requested count is greater than the remaining allocation in this window
     * the minted amount is reduced to consume the remaining allocation
     *
     * @param count the number of masks to mint
     */
    function mintMasksWithDefyTokens(uint256 count) public whenNotPaused {
        require (count > 0, "DEFYUprisingSalePhaseTwo: count must be greater than 0");

        uint256 currentMintWindow = getMintWindow(getCurrentTime());

        uint256 remainingMasksForCurrentWindow = getRemainingMasksForWindow(currentMintWindow);
        require(remainingMasksForCurrentWindow > 0, "DEFYUprisingSalePhaseTwo: allocation for this window is exhausted");

        // If there are less than the requested count left, adjust it to give you the maximum amount based on what's left
        count = Math.min(count, remainingMasksForCurrentWindow);

        // This will fail if the user has not granted enough allowance
        defyToken.safeTransferFrom(
            msg.sender,
            receiver,
            mintPriceInDefy * count
        );

        // Mint the approved count of masks
        for (uint256 i = 0; i < count; i++) {
            defyUprisingMask.mintMask(msg.sender);
            mintWindowCounters[currentMintWindow].increment();
        }
    }

    /**
     * Mints an amount of uprising masks by spending $DEFY tokens AND invites
     * If the number of invites specified is greater than the remaining allocation in this window
     * the minted amount is reduced to consume the remaining allocation
     *
     * @param inviteIds the invites to be burned in this transaction
     */
    function mintMasksWithDefyTokensAndInvites(uint256[] calldata inviteIds) public whenNotPaused {
        require (inviteIds.length > 0, "DEFYUprisingSalePhaseTwo: must specify at least one invite");

        uint256 currentMintWindow = getMintWindow(getCurrentTime());

        uint256 remainingMasksForCurrentWindow = getRemainingInviteMasksForWindow(currentMintWindow) + getRemainingMasksForWindow(currentMintWindow);
        require(remainingMasksForCurrentWindow > 0, "DEFYUprisingSalePhaseTwo: allocation for this window is exhausted");

        // If there are less than the requested count left, adjust it to give you the maximum amount based on what's left
        uint256 count = Math.min(inviteIds.length, remainingMasksForCurrentWindow);

        // Mint the approved count of masks
        for (uint256 i = 0; i < count; i++) {
            // Get invite metadata
            address originalOwner = defyUprisingInvite.getOriginalOwner(inviteIds[i]);

            // Burn the invite
            defyUprisingInvite.spendInvite(inviteIds[i], msg.sender);

            // If the original owner of the invite is not the minter, send the commission to the original owner
            if (originalOwner != msg.sender) {
                defyToken.safeTransferFrom(
                    msg.sender,
                    originalOwner,
                    mintPriceInDefy / 2
                );
            }

            // Pay the mint price to the receiver address
            defyToken.safeTransferFrom(
                msg.sender,
                receiver,
                mintPriceInDefy / 2
            );

            // Mint the mask
            defyUprisingMask.mintMask(msg.sender);

            // Deduct from the invite pool first, then from the main pool
            if (mintWindowInviteCounters[currentMintWindow].current() < availableInviteMasksPerWindow) {
                mintWindowInviteCounters[currentMintWindow].increment();
            } else {
                mintWindowCounters[currentMintWindow].increment();
            }
        }
    }

    function mintMasksFromBlackmarketPurchase(uint256 count) public whenNotPaused onlyRole(APP_MINTER_ROLE) {
        require (count > 0, "DEFYUprisingSalePhaseTwo: count must be greater than 0");

        uint256 currentMintWindow = getMintWindow(getCurrentTime());

        uint256 remainingMasksForCurrentWindow = getRemainingMasksForWindow(currentMintWindow);
        require(remainingMasksForCurrentWindow > 0, "DEFYUprisingSalePhaseTwo: allocation for this window is exhausted");

        // If there are less than the requested count left, adjust it to give you the maximum amount based on what's left
        count = Math.min(count, remainingMasksForCurrentWindow);

        // Mint the approved count of masks
        for (uint256 i = 0; i < count; i++) {
            defyUprisingMask.mintMask(msg.sender);
            mintWindowCounters[currentMintWindow].increment();
        }
    }

    function getRemainingMasksForWindow(uint256 windowId) public view returns (uint256) {
        return availableMasksPerWindow - mintWindowCounters[windowId].current();
    }

    function getRemainingInviteMasksForWindow(uint256 windowId) public view returns (uint256) {
        return availableInviteMasksPerWindow - mintWindowInviteCounters[windowId].current();
    }

    function getMintWindow(uint256 timestamp) public view returns (uint256) {
        return ((timestamp - mintStartTime) / mintWindowSizeSeconds) + mintWindowOffset;
    }

    function getCurrentTime() private view returns (uint256) {
        return block.timestamp;
    }
}
