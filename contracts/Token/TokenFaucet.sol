// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @custom:security-contact michael@defylabs.xyz
contract TokenFaucet {
    using SafeERC20 for IERC20;

		IERC20 public token;

		constructor(IERC20 _token) {
			require(address(_token) != address(0), "TokenFaucet: Token address can't be 0");
			token = _token;
		}

    function requestTokens(uint256 amount) public {
        require (amount > 0, "TokenFaucet: count must be greater than 0");
				require (amount < 10000, "TokenFaucet: count must be less than 10000");

        token.safeTransfer(
            msg.sender,
            amount * 10 ** 18
        );
    }
}
