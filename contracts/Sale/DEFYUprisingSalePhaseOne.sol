// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../Invites/IDEFYUprisingInvite.sol";
import "../Masks/IDEFYUprisingMask.sol";

/// @custom:security-contact michael@defylabs.xyz
contract DEFYUprisingSalePhaseOne is Pausable, AccessControl {
	using Counters for Counters.Counter;

	Counters.Counter private _phaseMintedCounter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	bytes32 public constant BALANCE_WITHDRAWER_ROLE = keccak256("BALANCE_WITHDRAWER_ROLE");

	IDEFYUprisingInvite public defyUprisingInviteTier1;
	IDEFYUprisingInvite public defyUprisingInviteTier2;

	IDEFYUprisingMask public defyUprisingMask;

	// Commission divisors
    uint256 public tier1CommissionDivisor;
	uint256 public tier2CommissionDivisor;

	// Mint active flags
	bool public tier1MintActive;
	bool public tier2MintActive;

	// Price (in MATIC) required to mint a mask
    uint256 public mintPrice;

	// Mapping from phase id to total supply. ie, to cap phase 1 of the mint at 2000 masks, mintPhaseTotalSupply[1] == 2000
	uint256 public mintPhaseTotalSupply;

    constructor(address tier1Address, address tier2Address, address uprisingMaskAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);

		defyUprisingInviteTier1 = IDEFYUprisingInvite(tier1Address);
		defyUprisingInviteTier2 = IDEFYUprisingInvite(tier2Address);

		defyUprisingMask = IDEFYUprisingMask(uprisingMaskAddress);

		mintPhaseTotalSupply = 2000;
		mintPrice = 160 ether;
		tier1MintActive = false;
		tier2MintActive = false;
		tier1CommissionDivisor = 2;
		tier2CommissionDivisor = 10;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

	/// @notice Admin function to allow updating of mint phase total supply
	function setMintPhaseTotalSupply(uint256 totalSupply) external onlyRole(DEFAULT_ADMIN_ROLE) {
		mintPhaseTotalSupply = totalSupply;
	}

	/// @notice Admin function to allow updating of tier 1 contract address
    function updateInviteTier1ContractAddress(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
      defyUprisingInviteTier1 = IDEFYUprisingInvite(contractAddress);
    }

	/// @notice Admin function to allow updating of tier 2 contract address
    function updateInviteTier2ContractAddress(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
      defyUprisingInviteTier2 = IDEFYUprisingInvite(contractAddress);
    }

	/// @notice Admin function to allow updating of mask contracts
    function updateDefyUprisingMaskContractAddress(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
      defyUprisingMask = IDEFYUprisingMask(contractAddress);
    }

	/// @notice Admin function to allow updating of tier 1 commission divisor
    function updateTier1CommissionDivisor(uint256 newTier1CommissionDivisor) public onlyRole(DEFAULT_ADMIN_ROLE) {
      tier1CommissionDivisor = newTier1CommissionDivisor;
    }

	/// @notice Admin function to allow updating of tier 1 commission divisor
    function updateTier2CommissionDivisor(uint256 newTier2CommissionDivisor) public onlyRole(DEFAULT_ADMIN_ROLE) {
      tier2CommissionDivisor = newTier2CommissionDivisor;
    }

	/// @notice Admin function to allow updating of mint price
    function updateMintPrice(uint256 newMintPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
      mintPrice = newMintPrice;
    }

	/// @notice Admin function to update tier 1 mint active
    function updateTier1MintActive(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      tier1MintActive = active;
    }

	/// @notice Admin function to update tier 1 mint active
    function updateTier2MintActive(bool active) public onlyRole(DEFAULT_ADMIN_ROLE) {
      tier2MintActive = active;
    }

	function mintMasksWithInvites(uint256[] calldata tier1Invites, uint256[] calldata tier2Invites)
		public
		payable
		whenNotPaused()
	{
		if (tier1Invites.length > 0)
		{
			require(tier1MintActive, 'DEFYUprisingSale: tier 1 invite sale not active');
		}

		if (tier2Invites.length > 0)
		{
			require(tier2MintActive, 'DEFYUprisingSale: tier 2 invite sale not active');
		}

		uint256 currentTokenCount = _phaseMintedCounter.current();

		uint256 totalInvites = tier1Invites.length + tier2Invites.length;

		require((currentTokenCount + totalInvites) <= mintPhaseTotalSupply, 'DEFYUprisingSale: Trying to mint too many masks');

		require(msg.value == mintPrice * totalInvites, 'DEFYUprisingSale: incorrect token amount sent to mint');

		for (uint256 i = 0; i < tier1Invites.length; i++) 
		{
			// Get invite original owner
			address inviteOriginalOwner = defyUprisingInviteTier1.getOriginalOwner(tier1Invites[i]);

			// Spend invite
			defyUprisingInviteTier1.spendInvite(tier1Invites[i], msg.sender);

			// Mint mask
			defyUprisingMask.mintMask(msg.sender);

			// Pay commission to original owner of invite
			(bool success,) = inviteOriginalOwner.call{value : msg.value / totalInvites / tier1CommissionDivisor}('');

			require(success, "DEFYUprisingSale: tier 1 commission payment failed");

			_phaseMintedCounter.increment();
		}

		for (uint256 i = 0; i < tier2Invites.length; i++) 
		{
			// Pay required commission
			address inviteOriginalOwner = defyUprisingInviteTier2.getOriginalOwner(tier2Invites[i]);

			// Spend invite
			defyUprisingInviteTier2.spendInvite(tier2Invites[i], msg.sender);

			// Mint mask
			defyUprisingMask.mintMask(msg.sender);

			// Pay commission to original owner of invite
			(bool success,) = inviteOriginalOwner.call{value : msg.value / totalInvites / tier2CommissionDivisor}('');

			require(success, "DEFYUprisingSale: tier 2 commission payment failed");

			_phaseMintedCounter.increment();
		}
	}

    // Allow contract to receive MATIC directly
    receive() external payable {}

    // Allow withdrawal of the contract's current balance to the caller's address
    function withdrawBalance() public onlyRole(BALANCE_WITHDRAWER_ROLE) {
        (bool success,) = msg.sender.call{value : address(this).balance}('');
        require(success, "DUSPO: Withdrawal failed");
    }

    // Allow withdrawal of the contract's current balance to the caller's address
    function withdrawBalanceExceptFor(uint256 tokens) public onlyRole(BALANCE_WITHDRAWER_ROLE) {
        (bool success,) = msg.sender.call{value : address(this).balance - tokens}('');
        require(success, "DUSPO: Withdrawal failed");
    }
}
