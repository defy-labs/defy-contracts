// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../Items/IDEFYLoot.sol";
import "./IDEFYDrone.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DEFYUpdateDrone is Pausable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _updateJobIds;

    bytes32 public constant DRONE_UPDATER_ROLE =
        keccak256("DRONE_UPDATER_ROLE");

    struct UpdateJob {
        IDEFYLoot lootContract;
        IDEFYDrone droneContract;
        address operativeAddress;
        uint256[] inputLootIds;
        uint256[] inputLootAmounts;
        uint256 droneId;
        uint256 updateJobId;
    }

    // Mapping from updateJobIds to UpdateJob struct
    mapping(uint256 => UpdateJob) private updateJobs;

    // Mapping from operative address to UpdateJobIds of operative
    mapping(address => uint256[]) private operativesUpdateJobsIds;

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validLootContracts;

    // Mapping from IDEFYDrone to validity contract condition
    mapping(IDEFYDrone => bool) private validDroneContracts;

    // Event indexed by operative address and updateJobId
    event UpdateDrone(
        address indexed operativeAddress,
        uint256 indexed updateJobId,
        uint256 indexed droneTokenId,
        uint256[] inputLootIds,
        uint256[] inputLootAmounts
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Updates a Drone for an operative.
     *      Burns the input loots.
     */
    function updateDrone(
        IDEFYLoot lootContract,
        IDEFYDrone droneContract,
        address operativeAddress,
        uint256[] calldata inputLootIds,
        uint256[] calldata inputLootAmounts,
        uint256 droneTokenId
    ) public onlyRole(DRONE_UPDATER_ROLE) {
        // require call is made to a valid loot contract
        require(
            validLootContracts[lootContract] == true,
            "DEFYUpdateDrone: Loot contract not valid"
        );

        // require call is made to a valid drone contract
        require(
            validDroneContracts[droneContract] == true,
            "DEFYUpdateDrone: Drone contract not valid"
        );

        // require input arrays are not null
        require(
            inputLootAmounts.length != 0 && inputLootIds.length != 0,
            "DEFYUpdateDrone: Invalid input loots"
        );

        // require input loots ids and amount are the same
        require(
            inputLootAmounts.length == inputLootIds.length,
            "DEFYUpdateDrone: All arrays must be the same length"
        );

        // require operative owns the drone NFT
        require(
            droneContract.ownerOf(droneTokenId) == operativeAddress,
            "DEFYUpdateDrone: Operative does not own drone"
        );

        // require operative has tokens available
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddress, inputLootIds[i]) >=
                    inputLootAmounts[i],
                "DEFYUpdateDrone: Operative does not have suffient loots"
            );
        }

        // create updating record
        uint256 updateJobId = _updateJobIds.current();

        // increment _updateJobId counter
        _updateJobIds.increment();

        // Add new update job to storage mapping
        updateJobs[updateJobId] = UpdateJob(
            lootContract,
            droneContract,
            operativeAddress,
            inputLootIds,
            inputLootAmounts,
            droneTokenId,
            updateJobId
        );

        // Add update job id to operatives list
        operativesUpdateJobsIds[operativeAddress].push(updateJobId);

        // burn input loots
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            lootContract.burnToken(
                operativeAddress,
                inputLootIds[i],
                inputLootAmounts[i]
            );
        }

        emit UpdateDrone(
            operativeAddress,
            updateJobId,
            droneTokenId,
            inputLootIds,
            inputLootAmounts
        );
    }

    /**
     * @dev Returns the number of update jobs.
     * @return the number of update jobs.
     */
    function getUpdateJobsCount() public view returns (uint256) {
        return _updateJobIds.current();
    }

    /**
     * @notice Returns the update job information for a given identifier.
     * @return the update job structure information
     */
    function getUpdateJob(uint256 updateJobId)
        public
        view
        returns (UpdateJob memory)
    {
        return updateJobs[updateJobId];
    }

    /**
     * @dev Returns the number of update jobs associated to an operative.
     * @return the number of update jobs
     */
    function getUpdateJobsCountByOperative(address operative)
        external
        view
        returns (uint256)
    {
        return operativesUpdateJobsIds[operative].length;
    }

    /**
     * @dev Returns the update jobs id associated to an operative based on an array index value.
     * @return the updatejobId
     */
    function getUpdateJobIdForOwnerByIndex(address operative, uint256 index)
        public
        view
        returns (uint256)
    {
        return operativesUpdateJobsIds[operative][index];
    }

    /**
     * @dev Returns the array of update job ids for an operative.
     * @return the array of updateJobIds
     */
    function getAllUpdateJobIdsForOwner(address operative)
        public
        view
        returns (uint256[] memory)
    {
        return operativesUpdateJobsIds[operative];
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
     * @dev Approves an IDEFYLoot contract address for updating.
     */
    function approveLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for updating.
     */
    function revokeLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = false;
    }

    /**
     * @dev Approves an IDEFYDrone contract address for updating.
     */
    function approveDroneContract(IDEFYDrone iDEFYDrone)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validDroneContracts[iDEFYDrone] = true;
    }

    /**
     * @dev Revokes an IDEFYDrone contract address for updating.
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
