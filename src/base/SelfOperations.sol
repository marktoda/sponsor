// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {Currency, CurrencyLibrary} from "../lib/CurrencyLib.sol";

/// @notice operations that can be performed on the router contract itself
abstract contract SelfOperations {
    using FixedPointMathLib for uint256;
    using CurrencyLibrary for Currency;

    error EthSweepFailed();
    error InvalidEscalatorTimes();
    error InvalidEscalatorAmounts();

    /// @notice sweep all tokens of a given type from the router contract
    /// @param currency the currency to sweep
    /// @param recipient the recipient of the sweeped tokens
    function sweep(Currency currency, address recipient) public {
        currency.transfer(recipient, currency.balanceOfSelf());
    }

    /// @notice send a tip to `msg.sender` for performing the execution
    /// @param currency The currency to tip in
    function tip(Currency currency, uint256 amount) public {
        currency.transfer(msg.sender, amount);
    }

    /// @notice send an escalating tip to `msg.sender` for performing the execution
    /// @param currency The currency to tip in
    /// @param startTime The time at which the escalator begins to escalate
    /// @param endTime The time at which the escalator stops escalating
    /// @param startAmount The amount of currencys the escalator starts with at startTime
    /// @param endAmount The amount of currencys the escalator ends with at endTime
    function tipEscalating(
        Currency currency,
        uint256 startTime,
        uint256 endTime,
        uint256 startAmount,
        uint256 endAmount
    ) public {
        uint256 amount = resolveEscalator(startTime, endTime, startAmount, endAmount);
        currency.transfer(msg.sender, amount);
    }

    /// @notice resolve the current value of a fee escalator
    /// @param startTime The time at which the escalator begins to escalate
    /// @param endTime The time at which the escalator stops escalating
    /// @param startAmount The amount of tokens the escalator starts with at startTime
    /// @param endAmount The amount of tokens the escalator ends with at endTime
    function resolveEscalator(uint256 startTime, uint256 endTime, uint256 startAmount, uint256 endAmount)
        internal
        view
        returns (uint256)
    {
        if (endTime < startTime) {
            revert InvalidEscalatorTimes();
        }

        if (endAmount < startAmount) {
            revert InvalidEscalatorAmounts();
        }

        if (endTime <= block.timestamp) {
            return endAmount;
        }

        if (startTime >= block.timestamp) {
            return startAmount;
        }

        unchecked {
            uint256 elapsed = block.timestamp - startTime;
            uint256 duration = endTime - startTime;
            return startAmount + (endAmount - startAmount).mulDivDown(elapsed, duration);
        }
    }
}
