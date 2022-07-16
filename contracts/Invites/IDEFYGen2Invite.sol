// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDEFYGen2Invite {
  function spendInvite (uint256 tokenId, address spender) external;
  function getOriginalOwner (uint256 tokenId) external view returns (address);
}
