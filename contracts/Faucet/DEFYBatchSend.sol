// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// ______ _____________   __
// |  _  \  ___|  ___\ \ / /
// | | | | |__ | |_   \ V /
// | | | |  __||  _|   \ /
// | |/ /| |___| |     | |
// |___/ \____/\_|     \_/
//
// WELCOME TO THE REVOLUTION

contract DEFYBatchSend is Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SENDER_ROLE = keccak256("SENDER_ROLE");

    uint256 private sendAmount;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawAllMatic(
        address payable to
    ) external payable whenNotPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 amount = getBalance();
        (bool success, ) = to.call{value: amount}("");
        require(success, "transaction failed");
    }

    function batchSend(
        address[] calldata operativeAddresses
    ) public payable onlyRole(SENDER_ROLE) whenNotPaused {
        for (uint256 i; i < operativeAddresses.length; i++) {
            (bool success, ) = operativeAddresses[i].call{value: sendAmount}(
                ""
            );
            require(success, "transaction failed");
        }
    }

    function setSendAmount(
        uint256 newSendAmount
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        sendAmount = newSendAmount;
    }

    // receives matic
    receive() external payable {}

    fallback() external payable {}
}
