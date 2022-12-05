// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../Items/IDEFYLoot.sol";
import "./IDEFYDrone.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DEFYCraftDrone is Pausable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _craftJobIds;

    bytes32 public constant DRONE_CRAFTER_ROLE =
        keccak256("DRONE_CRAFTER_ROLE");

    struct CraftJob {
        IDEFYLoot lootContract;
        IDEFYDrone droneContract;
        address operativeAddress;
        uint256[] inputLootIds;
        uint256[] inputLootAmounts;
        uint256 craftLootId;
    }

    // Mapping from craftJobIds to CraftJob struct
    mapping(uint256 => CraftJob) private craftJobs;

    // Mapping from operative address to CraftJobIds of operative
    mapping(address => uint256[]) private operativesCraftJobsIds;

    // Mapping from craftJobId to droneTokenId
    mapping(uint256 => uint256) private droneTokenId;

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validLootContracts;

    // Mapping from IDEFYDrone to validity contract condition
    mapping(IDEFYDrone => bool) private validDroneContracts;

    // Event indexed by operative address and craftJobId
    event CraftDrone(
        address indexed operativeAddress,
        uint256 indexed craftJobId,
        uint256 indexed droneTokenId,
        uint256[] inputLootIds,
        uint256[] inputLootAmounts
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Crafts a Drone for an operative.
     *      Burns the input loots.
     * @return minted TokenId from DEFYDrone.
     */
    function craftDrone(
        IDEFYLoot lootContract,
        IDEFYDrone droneContract,
        address operativeAddress,
        uint256[] calldata inputLootIds,
        uint256[] calldata inputLootAmounts
    ) public onlyRole(DRONE_CRAFTER_ROLE) returns (uint256) {
        // require call is made to a valid loot contract
        require(
            validLootContracts[lootContract] == true,
            "DEFYCraftDrone: Loot contract not valid"
        );

        // require call is made to a valid drone contract
        require(
            validDroneContracts[droneContract] == true,
            "DEFYCraftDrone: Drone contract not valid"
        );

        // require input arrays are not null
        require(
            inputLootAmounts.length != 0 && inputLootIds.length != 0,
            "DEFYCraftDrone: Invalid input loots"
        );

        // require input loots ids and amount are the same
        require(
            inputLootAmounts.length == inputLootIds.length,
            "DEFYCraftDrone: All arrays must be the same length"
        );

        // require operative has tokens available
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddress, inputLootIds[i]) >=
                    inputLootAmounts[i],
                "DEFYCraftDrone: Operative does not have suffient loots"
            );
        }

        // create crafting record
        uint256 craftJobId = _craftJobIds.current();

        // increment _craftJobId counter
        _craftJobIds.increment();

        // Add new craft job to storage mapping
        craftJobs[craftJobId] = CraftJob(
            lootContract,
            droneContract,
            operativeAddress,
            inputLootIds,
            inputLootAmounts,
            craftJobId
        );

        // Add craft job id to operatives list
        operativesCraftJobsIds[operativeAddress].push(craftJobId);

        // burn input loots
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            lootContract.burnToken(
                operativeAddress,
                inputLootIds[i],
                inputLootAmounts[i]
            );
        }

        // mint ERC721 drone
        uint256 newDroneTokenId = droneContract.safeMint(operativeAddress);

        // store droneTokenId
        droneTokenId[craftJobId] = newDroneTokenId;

        emit CraftDrone(
            operativeAddress,
            craftJobId,
            newDroneTokenId,
            inputLootIds,
            inputLootAmounts
        );

        return craftJobId;
    }

    /**
     * @dev returns the Drone Token Id for a Craft Job Id input
     */
    function getDroneTokenId(uint256 craftJobId) public view returns (uint256) {
        return droneTokenId[craftJobId];
    }

    /**
     * @dev Returns the number of craft jobs.
     * @return the number of craft jobs.
     */
    function getCraftJobsCount() public view returns (uint256) {
        return _craftJobIds.current();
    }

    /**
     * @notice Returns the craft job information for a given identifier.
     * @return the craft job structure information
     */
    function getCraftJob(uint256 craftJobId)
        public
        view
        returns (CraftJob memory)
    {
        return craftJobs[craftJobId];
    }

    /**
     * @dev Returns the number of craft jobs associated to an operative.
     * @return the number of craft jobs
     */
    function getCraftJobsCountByOperative(address operative)
        external
        view
        returns (uint256)
    {
        return operativesCraftJobsIds[operative].length;
    }

    /**
     * @dev Returns the craft jobs id associated to an operative based on an array index value.
     * @return the craftjobId
     */
    function getCraftJobIdForOwnerByIndex(address operative, uint256 index)
        public
        view
        returns (uint256)
    {
        return operativesCraftJobsIds[operative][index];
    }

    /**
     * @dev Returns the array of craft job ids for an operative.
     * @return the array of craftJobIds
     */
    function getAllCraftJobIdsForOwner(address operative)
        public
        view
        returns (uint256[] memory)
    {
        return operativesCraftJobsIds[operative];
    }

    /**
     * @dev Returns the validity of the an lootContract address.
     * @return the boolean of validity.
     */
    function getLootContractValidity(IDEFYLoot lootContract)
        public
        view
        returns (bool)
    {
        return validLootContracts[lootContract];
    }

    /**
     * @dev Returns the validity of the an droneContract address.
     * @return the boolean of validity.
     */
    function getDroneContractValidity(IDEFYDrone droneContract)
        public
        view
        returns (bool)
    {
        return validDroneContracts[droneContract];
    }

    /**
     * @dev Approves an IDEFYLoot contract address for crafting.
     */
    function approveLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for crafting.
     */
    function revokeLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = false;
    }

    /**
     * @dev Approves an IDEFYDrone contract address for crafting.
     */
    function approveDroneContract(IDEFYDrone iDEFYDrone)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validDroneContracts[iDEFYDrone] = true;
    }

    /**
     * @dev Revokes an IDEFYDrone contract address for crafting.
     */
    function revokeDroneContract(IDEFYDrone iDEFYDrone)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validDroneContracts[iDEFYDrone] = false;
    }

    /**
     * @dev Returns the block.timestamp.
     * @return the current block timestamp
     */
    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }
}
