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
    bytes32 public constant DEFYLOOT_ADMIN_ROLE =
        keccak256("DEFYLOOT_ADMIN_ROLE");

    enum State {
        processing,
        completed,
        cancelled,
        failed
    }

    struct ForgeJob {
        IDEFYLoot itemContract;
        address operativeAddress;
        uint256[] inputMaterialIds;
        uint256[] inputMaterialAmounts;
        uint256 startTime;
        uint256 endTime;
        uint256 blueprintId;
        uint256 outputLootId;
        State forgeJobState;
    }

    // Mapping from forgeJobIds to ForgeJob struct
    mapping(uint256 => ForgeJob) private forgeJobs;

    // Mapping from operative address to ForgeJobIds
    mapping(address => uint256[]) private operativesForgeJobsIds;

    // Mapping from IDEFYLoot to validity contract condition
    mapping(IDEFYLoot => bool) private validItemContracts;

    // Event indexed by operative address and forgeJobId, includes burned tokens.
    event CreateForge(
        address indexed _operativeAddress,
        uint256 indexed _forgeJobId,
        uint256[] _inputMaterialIds,
        uint256[] _inputMaterialAmounts
    );

    // Event indexed by operative address and forgeJobId, includes minted tokens.
    event CompleteForge(
        address indexed _operativeAddress,
        uint256 indexed _forgeJobId,
        uint256 _outputLootId
    );

    // Event indexed by operative address and forgeJobId.
    event CancelForge(
        address indexed _operativeAddress,
        uint256 indexed _forgeJobId,
        uint256[] _remintedMaterialIds,
        uint256[] _remintedMaterialAmounts
    );

    // Event indexed by operative address and forgeJobId.
    event FailForge(
        address indexed _operativeAddress,
        uint256 indexed _forgeJobId
    );

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Create a forge job for an operative.
     *      Burns the input materials.
     * @return the forge job id.
     */
    // Forges (mints) a new part and burns the input materials
    function createForge(
        IDEFYLoot itemContract,
        address operativeAddress,
        uint256[] calldata inputMaterialIds,
        uint256[] calldata inputMaterialAmounts,
        uint256 duration,
        uint256 blueprintId,
        uint256 outputLootId
    ) public onlyRole(FORGER_ROLE) returns (uint256) {
        // require call is made to a valid item contract
        require(
            validItemContracts[itemContract] == true,
            "DEFYForge: Item contract not valid"
        );

        // require input arrays are not null
        require(
            inputMaterialAmounts.length != 0 && inputMaterialIds.length != 0,
            "DEFYForge: Invalid input materials"
        );

        // require input materials ids and amount are the same
        require(
            inputMaterialAmounts.length == inputMaterialIds.length,
            "DEFYForge: All arrays must be the same length"
        );

        // require operative has tokens available
        for (uint256 i = 0; i < inputMaterialIds.length; i++) {
            require(
                itemContract.balanceOf(operativeAddress, inputMaterialIds[i]) >=
                    inputMaterialAmounts[i],
                "DEFYForge: Operative does not have suffient materials"
            );
        }

        // create print job record
        uint256 forgeJobId = _forgeJobIds.current();

        // Add new forge job to storage mapping
        forgeJobs[forgeJobId] = ForgeJob(
            itemContract,
            operativeAddress,
            inputMaterialIds,
            inputMaterialAmounts,
            timeNow(),
            timeNow() + duration,
            blueprintId,
            outputLootId,
            State.processing
        );

        // Add forge job id to operatives list
        operativesForgeJobsIds[operativeAddress].push(forgeJobId);

        // increment _forgeJobId counter
        _forgeJobIds.increment();

        // burn input materials
        for (uint256 i = 0; i < inputMaterialIds.length; i++) {
            itemContract.burnToken(
                operativeAddress,
                inputMaterialIds[i],
                inputMaterialAmounts[i]
            );
        }

        emit CreateForge(
            operativeAddress,
            forgeJobId,
            inputMaterialIds,
            inputMaterialAmounts
        );

        return forgeJobId;
    }

    /**
     * @dev Completes a forge job for an operative.
     *      Mints the output loot for an operative.
     * @return the number of forge jobs
     */
    // pass in forgeJobId and mint forged part
    function completeForge(uint256 _forgeJobId)
        public
        onlyRole(FORGER_ROLE)
        returns (address, uint256)
    {
        //require forgeJobId to be within the current bounds
        require(
            forgeJobsCount() >= _forgeJobId,
            "DEFYForge: ForgeJobId out of bounds"
        );

        // get ForgeJob struct
        ForgeJob memory _forgeJob = forgeJob(_forgeJobId);

        // require forgeJob state is processing
        require(
            _forgeJob.forgeJobState == State.processing,
            "DEFYForge: Forge is not processing"
        );

        // require duration has elasped
        require(
            _forgeJob.endTime <= block.timestamp,
            "DEFYForge: Forge is not ready to complete"
        );

        bytes memory zeroBytes;

        // Mint output part
        _forgeJob.itemContract.mint(
            _forgeJob.operativeAddress,
            _forgeJob.outputLootId,
            1,
            zeroBytes
        );

        forgeJobs[_forgeJobId].forgeJobState = State.completed;

        emit CompleteForge(
            _forgeJob.operativeAddress,
            _forgeJobId,
            _forgeJob.outputLootId
        );

        return (_forgeJob.operativeAddress, _forgeJob.outputLootId);
    }

    /**
     * @dev Manually cancels the forge state of forge job.
            Input items are returned to the operative, on a pro rata basis.
            No output item is minted.
     */
    function cancelForge(uint256 _forgeJobId) public onlyRole(FORGER_ROLE) {
        //require forgeJobId to be within the current bounds
        require(
            forgeJobsCount() >= _forgeJobId,
            "DEFYForge: ForgeJobId out of bounds"
        );

        // get ForgeJob struct
        ForgeJob memory _forgeJob = forgeJob(_forgeJobId);

        // require forgeJob state is processing
        require(
            _forgeJob.forgeJobState == State.processing,
            "DEFYForge: Forge has been completed"
        );

        // get input parts and data
        uint256[] memory _inputMaterialsIds = _forgeJob.inputMaterialIds;
        uint256[] memory _inputMaterialAmounts = _forgeJob.inputMaterialAmounts;
        uint256 _duration = (_forgeJob.endTime - _forgeJob.startTime);
        uint256 _now = block.timestamp;

        uint256 percentOfJobCompleted = (100 * (_now - _forgeJob.startTime)) /
            _duration;

        uint256[] memory toMintMaterialAmount;

        bytes memory zeroBytes;

        for (uint256 i = 0; i < _inputMaterialsIds.length; i++) {
            toMintMaterialAmount[i] =
                (percentOfJobCompleted * _inputMaterialAmounts[i]) /
                100;

            // Mint input parts, on a pro rata basis
            _forgeJob.itemContract.mint(
                _forgeJob.operativeAddress,
                _inputMaterialsIds[i],
                toMintMaterialAmount[i],
                zeroBytes
            );
        }

        forgeJobs[_forgeJobId].forgeJobState = State.cancelled;

        emit CancelForge(
            _forgeJob.operativeAddress,
            _forgeJobId,
            _inputMaterialsIds,
            toMintMaterialAmount
        );
    }

    /**
     * @dev Manually fails the forge state of forge job.
            No input items are returned to the operative.
            No output item is minted.
     */
    function failForge(uint256 _forgeJobId) public onlyRole(FORGER_ROLE) {
        //require forgeJobId to be within the current bounds
        require(
            forgeJobsCount() >= _forgeJobId,
            "DEFYForge: ForgeJobId out of bounds"
        );

        // get ForgeJob struct
        ForgeJob memory _forgeJob = forgeJob(_forgeJobId);

        // require forgeJob state is processing
        require(
            _forgeJob.forgeJobState == State.processing,
            "DEFYForge: Forge has been completed"
        );

        forgeJobs[_forgeJobId].forgeJobState = State.failed;

        emit FailForge(_forgeJob.operativeAddress, _forgeJobId);
    }

    /**
     * @dev Returns the number of forge jobs.
     * @return the number of forge jobs.
     */
    function forgeJobsCount() internal view returns (uint256) {
        return _forgeJobIds.current();
    }

    /**
     * @notice Returns the forge job information for a given identifier.
     * @return the forge job structure information
     */
    function forgeJob(uint256 forgeJobId)
        internal
        view
        returns (ForgeJob memory)
    {
        return forgeJobs[forgeJobId];
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
    function getForgeJobsCountByOperative(address _operative)
        external
        view
        returns (uint256)
    {
        return operativesForgeJobsIds[_operative].length;
    }

    /**
     * @dev Returns the forge jobs id associated to an operative based on an array index value.
     * @return the forgejobId
     */
    function getForgeJobIdForOwnerByIndex(address _operative, uint256 _index)
        public
        view
        returns (uint256)
    {
        return operativesForgeJobsIds[_operative][_index];
    }

    /**
     * @dev Returns the array of forge job ids for an operative.
     * @return the array of forgeJobIds
     */
    function getAllForgeJobIdsForOwner(address _operative)
        public
        view
        returns (uint256[] memory)
    {
        return operativesForgeJobsIds[_operative];
    }

    /**
     * @dev Returns the validity of the an itemContract address.
     * @return the boolean of validity.
     */
    function getItemContractValidity(IDEFYLoot _itemContract)
        public
        view
        returns (bool)
    {
        return validItemContracts[_itemContract];
    }

    /**
     * @dev Approves an IDEFYLoot contract address for forging.
     */
    function approveItemContract(IDEFYLoot _IDEFYLoot)
        public
        onlyRole(DEFYLOOT_ADMIN_ROLE)
    {
        validItemContracts[_IDEFYLoot] = true;
    }

    /**
     * @dev Revokes an IDEFYLoot contract address for forging.
     */
    function revokeItemContract(IDEFYLoot _IDEFYLoot)
        public
        onlyRole(DEFYLOOT_ADMIN_ROLE)
    {
        validItemContracts[_IDEFYLoot] = false;
    }

    /**
     * @dev Returns the block.timestamp.
     * @return the current block timestamp
     */
    function timeNow() public view returns (uint256) {
        return block.timestamp;
    }
}
