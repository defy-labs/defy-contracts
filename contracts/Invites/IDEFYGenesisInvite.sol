// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./InviteTypes.sol";

interface IDEFYGenesisInvite is InviteTypes {
  function spendInvite (uint256 tokenId, address spender) external;
  function getInviteMetadata (uint256 tokenId) external view returns (DEFYGenesisInviteMetadata memory);
}