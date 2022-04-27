//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MockVRFCoordinator {
  uint256 internal requestCounter = 0;

  function requestRandomWords(
      bytes32,
      uint64,
      uint16,
      uint32,
      uint32
  ) external returns (uint256) {
      requestCounter += 1;
      VRFConsumerBaseV2 consumer = VRFConsumerBaseV2(msg.sender);
      uint256[] memory randomWords = new uint256[](2);
      randomWords[0] = random();
      randomWords[1] = random()/7;
      consumer.rawFulfillRandomWords(requestCounter-1, randomWords);
      return requestCounter;
  }

  function random() private view returns (uint) {
    return uint(keccak256(abi.encode(block.timestamp + requestCounter)));
  } 
}
