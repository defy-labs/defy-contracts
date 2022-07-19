// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDEFYUprisingInvite {
  function spendInvite (uint256 tokenId, address spender) external;
  function getOriginalOwner (uint256 tokenId) external view returns (address);
}
