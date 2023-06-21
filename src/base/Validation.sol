// SPDX-License-Identifier: GPL-2.0-or-later
// from: Uniswap/v3-periphery
pragma solidity ^0.8.0;

abstract contract Validation {
    error TransactionExpired();
    error InvalidBlockHash();

    modifier checkDeadline(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert TransactionExpired();
        }
        _;
    }

    modifier checkPreviousBlockhash(bytes32 previousBlockhash) {
        if (blockhash(block.number - 1) != previousBlockhash) {
            revert InvalidBlockHash();
        }
        _;
    }
}
