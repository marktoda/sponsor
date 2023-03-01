// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

/// @notice operations that can be performed on the router contract itself
abstract contract SelfOperations {
    error EthSweepFailed();

    /// @notice sweep all tokens of a given type from the router contract
    /// @param token the token to sweep
    /// @param recipient the recipient of the sweeped tokens
    function sweep(address token, address recipient) public {
        ERC20(token).transfer(recipient, ERC20(token).balanceOf(address(this)));
    }

    /// @notice sweep all ETH from the router contract
    /// @param recipient the recipient of the sweeped ETH
    function sweepETH(address payable recipient) public {
        (bool success,) = recipient.call{value: address(this).balance}("");
        if (!success) {
            revert EthSweepFailed();
        }
    }
}
