// SPDX-License-Identifier: GPL-2.0-or-later
// from: Uniswap/v3-periphery
pragma solidity ^0.8.0;

import {Validation} from "./Validation.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is Validation {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param deadline The timestamp after which this transaction is invalid
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(uint256 deadline, bytes[] calldata data)
        external
        payable
        checkDeadline(deadline)
        returns (bytes[] memory)
    {
        return multicall(data);
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param previousBlockhash The expected parent blockHash
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes32 previousBlockhash, bytes[] calldata data)
        external
        payable
        checkPreviousBlockhash(previousBlockhash)
        returns (bytes[] memory)
    {
        return multicall(data);
    }
}
