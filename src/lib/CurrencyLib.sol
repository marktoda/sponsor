// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

type Currency is address;

/// @title CurrencyLibrary
/// @dev This library allows for transferring and holding native tokens and ERC20 tokens
library CurrencyLibrary {
    using CurrencyLibrary for Currency;
    using SafeTransferLib for ERC20;

    /// @notice Thrown when a native transfer fails
    error NativeTransferFailed();

    Currency public constant NATIVE = Currency.wrap(address(0));

    function transfer(Currency currency, address to, uint256 amount) internal {
        bool success;
        if (currency.isNative()) {
            assembly {
                // Transfer the ETH and store if it succeeded or not.
                success := call(gas(), to, amount, 0, 0, 0, 0)
            }

            if (!success) revert NativeTransferFailed();
        } else {
            ERC20(Currency.unwrap(currency)).safeTransfer(to, amount);
        }
    }

    function balanceOfSelf(Currency currency) internal view returns (uint256) {
        if (currency.isNative()) {
            return address(this).balance;
        } else {
            return ERC20(Currency.unwrap(currency)).balanceOf(address(this));
        }
    }

    function isNative(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == Currency.unwrap(NATIVE);
    }
}
