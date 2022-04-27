// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface InviteTypes {
  // Invite state. Once an invite is spent, it is no longer able to be transferred and cannot be made active again
  enum InviteState {
    ACTIVE,
    SPENT
  }

  // Onchain metadata for the invite
  struct DEFYGenesisInviteMetadata {
    address originalOwner; // Store the original owner to track who to send commission to
    InviteState inviteState; // Current state of this token
    uint8 seriesId; // Series of this invite
  }
}