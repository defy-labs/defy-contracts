// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./IDEFYItems.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract DEFYForge is Pausable, AccessControl {
    bytes32 public constant FORGER_ROLE = keccak256("FORGER_ROLE");

    struct PrintJob {
        IERC1155 itemContract;
        address operativeAddress;
        uint256[] inputMaterialsId;
        uint256[] inputMaterialsAmount;
        uint256 blueprintId;
        uint256 outputPartId;
        bool completed;
    }

    bytes32[] private printJobIds;
    mapping(bytes32 => PrintJob) private printJobs;
    mapping(address => uint256) private operativesPrintJobCount;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // Forges (mints) a new part and burns the input materials
    function createForge(
        IERC1155 itemContract,
        address operativeAddress,
        uint256[] calldata inputMaterialsId,
        uint256[] calldata inputMaterialsAmount,
        uint256 blueprintId,
        uint256 outputPartId
    ) public onlyRole(FORGER_ROLE) returns (bytes32 _printJobId) {
        // require operative has the blueprint
        require(
            itemContract.balanceOf(operativeAddress, blueprintId) != 0,
            "DEFYForge: Operative does not own blueprint"
        );

        // require input arrays are not null
        require(
            inputMaterialsAmount.length != 0 && inputMaterialsId.length != 0,
            "DEFYForge: Invalid input materials"
        );

        // require input materials ids and amount are the same
        require(
            inputMaterialsAmount.length == inputMaterialsId.length,
            "DEFYForge: All arrays must be the same length"
        );

        // require operative has tokens available
        for (uint256 i = 0; i < inputMaterialsId.length; i++) {
            require(
                itemContract.balanceOf(operativeAddress, inputMaterialsId[i]) >=
                    inputMaterialsAmount[i],
                "DEFYForge: Operative does not have suffient materials"
            );
        }

        // create print job record
        bytes32 printJobId = computeNextPrintJobIdForOperative(
            operativeAddress
        );

        printJobs[printJobId] = PrintJob(
            itemContract,
            operativeAddress,
            inputMaterialsId,
            inputMaterialsAmount,
            blueprintId,
            outputPartId,
            false
        );

        printJobIds.push(printJobId);
        uint256 currentPrintJobCount = operativesPrintJobCount[
            operativeAddress
        ];
        operativesPrintJobCount[operativeAddress] = currentPrintJobCount + 1;

        // burn input materials

        for (uint256 i = 0; i < inputMaterialsId.length; i++) {
            itemContract.burnToken(
                operativeAddress,
                inputMaterialsId[i],
                inputMaterialsAmount[i]
            );
        }

        // return printJobId
        return printJobId;
    }

    // pass in printJobId and mint forged part
    function completeForge(bytes32 _printJobId)
        public
        onlyRole(FORGER_ROLE)
        returns (address, uint256)
    {
        // require printJob has not been completed
        require(
            getPrintJob(_printJobId).completed == false,
            "DEFYForge: Forge has been completed"
        );

        // get PrintJob struct
        PrintJob memory _printJob = getPrintJob(_printJobId);
        bytes memory zeroBytes;

        // Mint output part
        _printJob.itemContract.mint(
            _printJob.operativeAddress,
            _printJob.outputPartId,
            1,
            zeroBytes
        );

        printJobs[_printJobId].completed = true;

        return (_printJob.operativeAddress, _printJob.outputPartId);
    }

    /**
     * @dev Returns the print job id at the given index.
     * @return the print job id
     */
    function getPrintJobIdAtIndex(uint256 index)
        external
        view
        returns (bytes32)
    {
        require(index < getPrintJobsCount(), "DEFYForge: index out of bounds");
        return printJobIds[index];
    }

    /**
     * @dev Returns the number of print jobs created by an operative.
     * @return the number of print jobs
     */
    function getPrintJobsCount() public view returns (uint256) {
        return printJobIds.length;
    }

    /**
     * @notice Returns the print job information for a given identifier.
     * @return the print job structure information
     */
    function getPrintJob(bytes32 printJobId)
        public
        view
        returns (PrintJob memory)
    {
        return printJobs[printJobId];
    }

    /**
     * @dev Returns the number of print jobs associated to a operative.
     * @return the number of print jobs
     */
    function getPrintJobsCountByOperative(address _operative)
        external
        view
        returns (uint256)
    {
        return operativesPrintJobCount[_operative];
    }

    /**
     * @dev Returns the print job id at the given index.
     * @return the print job id
     */
    function getVestingIdAtIndex(uint256 index)
        external
        view
        returns (bytes32)
    {
        require(index < getPrintJobsCount(), "DEFYForge: index out of bounds");
        return printJobIds[index];
    }

    /**
     * @notice Returns the print job information for a given operative and index.
     * @return the print job structure information
     */
    function getPrintJobByAddressAndIndex(address operative, uint256 index)
        external
        view
        returns (PrintJob memory)
    {
        return
            getPrintJob(computePrintJobIdForAddressAndIndex(operative, index));
    }

    /**
     * @dev Computes the next print job identifier for a given operative address.
     */
    function computeNextPrintJobIdForOperative(address operative)
        public
        view
        returns (bytes32)
    {
        return
            computePrintJobIdForAddressAndIndex(
                operative,
                operativesPrintJobCount[operative]
            );
    }

    /**
     * @dev Returns the last print job for a given operative address.
     */
    function getLastPrintJobForOperative(address operative)
        external
        view
        returns (PrintJob memory)
    {
        return
            printJobs[
                computePrintJobIdForAddressAndIndex(
                    operative,
                    operativesPrintJobCount[operative] - 1
                )
            ];
    }

    /**
     * @dev Computes the print job identifier for an address and an index.
     */
    function computePrintJobIdForAddressAndIndex(
        address operative,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(operative, index));
    }
}
