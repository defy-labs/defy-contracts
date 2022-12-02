// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IDEFYLoot.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DEFYForge is Pausable, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _forgeJobIds;

    bytes32 public constant FORGER_ROLE = keccak256("FORGER_ROLE");

    enum State {
        Processing,
        Completed,
        Cancelled,
        Failed
    }

    struct ForgeJob {
        IDEFYLoot lootContract;
        address operativeAddress;
        uint256[] inputLootIds;
        uint256[] inputLootAmounts;
        uint256 startTime;
        uint256 endTime;
        uint256 blueprintId;
        uint256 outputLootId;
        State forgeJobState;
    }

    // Mapping from forgeJobIds to ForgeJob struct
    mapping(uint256 => ForgeJob) private forgeJobs;

    // Mapping from operative address to ForgeJobIds of operative
    mapping(address => uint256[]) private operativesForgeJobsIds;

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validLootContracts;

    // Event indexed by operative address and forgeJobId, includes burned tokens.
    event CreateForgeJob(
        address indexed operativeAddress,
        uint256 indexed forgeJobId,
        uint256 indexed blueprintId,
        uint256[] inputLootIds,
        uint256[] inputLootAmounts
    );

    // Event indexed by operative address and forgeJobId, includes minted tokens.
    event CompleteForgeJob(
        address indexed operativeAddress,
        uint256 indexed forgeJobId,
        uint256 indexed blueprintId,
        uint256 outputLootId
    );

    // Event indexed by operative address and forgeJobId.
    event CancelForgeJob(
        address indexed operativeAddress,
        uint256 indexed forgeJobId,
        uint256[] remintedLootIds,
        uint256[] remintedLootAmounts
    );

    // Event indexed by operative address and forgeJobId.
    event FailForgeJob(
        address indexed operativeAddress,
        uint256 indexed forgeJobId
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Create a forge job for an operative.
     *      Burns the input loots.
     * @return the forge job id.
     */
    function createForgeJob(
        IDEFYLoot lootContract,
        address operativeAddress,
        uint256[] calldata inputLootIds,
        uint256[] calldata inputLootAmounts,
        uint256 duration,
        uint256 blueprintId,
        uint256 outputLootId
    ) public onlyRole(FORGER_ROLE) returns (uint256) {
        // require call is made to a valid loot contract
        require(
            validLootContracts[lootContract] == true,
            "DEFYForge: Loot contract not valid"
        );

        // require input arrays are not null
        require(
            inputLootAmounts.length != 0 && inputLootIds.length != 0,
            "DEFYForge: Invalid input loots"
        );

        // require input loots ids and amount are the same
        require(
            inputLootAmounts.length == inputLootIds.length,
            "DEFYForge: All arrays must be the same length"
        );

        // require operative has tokens available
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            require(
                lootContract.balanceOf(operativeAddress, inputLootIds[i]) >=
                    inputLootAmounts[i],
                "DEFYForge: Operative does not have suffient loots"
            );
        }

        // create print job record
        uint256 forgeJobId = _forgeJobIds.current();

        // increment _forgeJobId counter
        _forgeJobIds.increment();

        // Add new forge job to storage mapping
        forgeJobs[forgeJobId] = ForgeJob(
            lootContract,
            operativeAddress,
            inputLootIds,
            inputLootAmounts,
            timeNow(),
            timeNow() + duration,
            blueprintId,
            outputLootId,
            State.Processing
        );

        // Add forge job id to operatives list
        operativesForgeJobsIds[operativeAddress].push(forgeJobId);

        // burn input loots
        for (uint256 i = 0; i < inputLootIds.length; i++) {
            lootContract.burnToken(
                operativeAddress,
                inputLootIds[i],
                inputLootAmounts[i]
            );
        }

        emit CreateForgeJob(
            operativeAddress,
            forgeJobId,
            blueprintId,
            inputLootIds,
            inputLootAmounts
        );

        return forgeJobId;
    }

    /**
     * @dev Completes a forge job for an operative.
     *      Mints the output loot for an operative.
     * @return the number of forge jobs
     */
    function completeForgeJob(uint256 forgeJobId)
        public
        onlyRole(FORGER_ROLE)
        returns (address, uint256)
    {
        //require forgeJobId to be within the current bounds
        require(
            getForgeJobsCount() >= forgeJobId,
            "DEFYForge: ForgeJobId out of bounds"
        );

        // get ForgeJob struct
        ForgeJob memory forgeJob = getForgeJob(forgeJobId);

        // require forgeJob state is processing
        require(
            forgeJob.forgeJobState == State.Processing,
            "DEFYForge: ForgeJob is not processing"
        );

        // require duration has elasped
        require(
            forgeJob.endTime <= block.timestamp,
            "DEFYForge: ForgeJob is not ready to complete"
        );

        bytes memory zeroBytes;

        // Mint output part
        forgeJob.lootContract.mint(
            forgeJob.operativeAddress,
            forgeJob.outputLootId,
            1,
            zeroBytes
        );

        forgeJobs[forgeJobId].forgeJobState = State.Completed;

        emit CompleteForgeJob(
            forgeJob.operativeAddress,
            forgeJobId,
            forgeJob.blueprintId,
            forgeJob.outputLootId
        );

        return (forgeJob.operativeAddress, forgeJob.outputLootId);
    }

    /**
     * @dev Manually cancels the forge state of forge job.
            Input loots are returned to the operative, on a pro rata basis.
            No output loot is minted.
     */
    function cancelForgeJob(uint256 forgeJobId) public onlyRole(FORGER_ROLE) {
        //require forgeJobId to be within the current bounds
        require(
            getForgeJobsCount() >= forgeJobId,
            "DEFYForge: ForgeJobId out of bounds"
        );

        // get ForgeJob struct
        ForgeJob memory forgeJob = getForgeJob(forgeJobId);

        // require forgeJob state is processing
        require(
            forgeJob.forgeJobState == State.Processing,
            "DEFYForge: Forge has been completed"
        );

        // get input parts and data
        uint256 duration = (forgeJob.endTime - forgeJob.startTime);
        uint256 percentOfJobCompleted;

        if (timeNow() - forgeJob.startTime >= duration) {
            percentOfJobCompleted = 100;
        } else {
            percentOfJobCompleted =
                (100 * (timeNow() - forgeJob.startTime)) /
                duration;
        }

        uint256[] memory toMintLootAmount = forgeJob.inputLootAmounts;

        bytes memory zeroBytes;

        for (uint256 i = 0; i < forgeJob.inputLootIds.length; i++) {
            toMintLootAmount[i] =
                ((100 - percentOfJobCompleted) * forgeJob.inputLootAmounts[i]) /
                100;

            // Mint input parts, on a pro rata basis
            forgeJob.lootContract.mint(
                forgeJob.operativeAddress,
                forgeJob.inputLootIds[i],
                toMintLootAmount[i],
                zeroBytes
            );
        }

        forgeJobs[forgeJobId].forgeJobState = State.Cancelled;

        emit CancelForgeJob(
            forgeJob.operativeAddress,
            forgeJobId,
            forgeJob.inputLootAmounts,
            toMintLootAmount
        );
    }

    /**
     * @dev Manually fails the forge state of forge job.
            No input loots are returned to the operative.
            No output loot is minted.
     */
    function failForgeJob(uint256 forgeJobId) public onlyRole(FORGER_ROLE) {
        //require forgeJobId to be within the current bounds
        require(
            getForgeJobsCount() >= forgeJobId,
            "DEFYForge: ForgeJobId out of bounds"
        );

        // get ForgeJob struct
        ForgeJob memory forgeJob = getForgeJob(forgeJobId);

        // require forgeJob state is processing
        require(
            forgeJob.forgeJobState == State.Processing,
            "DEFYForge: Forge has been completed"
        );

        forgeJobs[forgeJobId].forgeJobState = State.Failed;

        emit FailForgeJob(forgeJob.operativeAddress, forgeJobId);
    }

    /**
     * @dev Returns the number of forge jobs.
     * @return the number of forge jobs.
     */
    function getForgeJobsCount() public view returns (uint256) {
        return _forgeJobIds.current();
    }

    /**
     * @notice Returns the forge job information for a given identifier.
     * @return the forge job structure information
     */
    function getForgeJob(uint256 forgeJobId)
        public
        view
        returns (ForgeJob memory)
    {
        return forgeJobs[forgeJobId];
    }

    /**
     * @dev Returns the number of forge jobs associated to an operative.
     * @return the number of forge jobs
     */
    function getForgeJobsCountByOperative(address operative)
        external
        view
        returns (uint256)
    {
        return operativesForgeJobsIds[operative].length;
    }

    /**
     * @dev Returns the forge jobs id associated to an operative based on an array index value.
     * @return the forgejobId
     */
    function getForgeJobIdForOwnerByIndex(address operative, uint256 index)
        public
        view
        returns (uint256)
    {
        return operativesForgeJobsIds[operative][index];
    }

    /**
     * @dev Returns the array of forge job ids for an operative.
     * @return the array of forgeJobIds
     */
    function getAllForgeJobIdsForOwner(address operative)
        public
        view
        returns (uint256[] memory)
    {
        return operativesForgeJobsIds[operative];
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
     * @dev Returns the remaining time in seconds for an operatives forge job.
     *      Or Returns 0 if job is ready to complete.
     * @return remaining time for a forge job id.
     */
    function getRemainingTimeForForgeJob(uint256 forgeJobId)
        public
        view
        returns (uint256)
    {
        if (forgeJobs[forgeJobId].endTime > timeNow()) {
            return forgeJobs[forgeJobId].endTime - timeNow();
        } else {
            return 0;
        }
    }

    /**
     * @dev Approves an IDEFYLoot contract address for forging.
     */
    function approveLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for forging.
     */
    function revokeLootContract(IDEFYLoot iDEFYLoot)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        validLootContracts[iDEFYLoot] = false;
    }

    /**
     * @dev Returns the block.timestamp.
     * @return the current block timestamp
     */
    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }
}
