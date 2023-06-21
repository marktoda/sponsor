// SPDX-License-Identifier: GPL-2.0-or-later
// from: Uniswap/v3-periphery
pragma solidity ^0.8.0;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
/// @dev These functions are expected to be embedded in multicalls to allow EOAs to approve a contract and call a function
/// that requires an approval in a single transaction.
abstract contract Permit2Setup {
    ISignatureTransfer public immutable permit2 = ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    /// @notice Permits this contract to spend a given token from `owner`
    /// @dev The `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param owner The address who owns the tokens being permitted
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit2Setup(address token, address owner, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        payable
    {
        IERC20Permit(token).permit(owner, address(permit2), value, deadline, v, r, s);
    }

    /// @notice Permits this contract to spend a given token from `owner`
    /// @dev `spender` is always address(this).
    /// Can be used instead of #permit2Setup to prevent calls from failing due to a frontrun of a call to #permit2Setup
    /// @param token The address of the token spent
    /// @param owner The address who owns the tokens being permitted
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit2SetupIfNecessary(
        address token,
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        if (IERC20(token).allowance(owner, address(permit2)) < value) {
            permit2Setup(token, owner, value, deadline, v, r, s);
        }
    }
}
