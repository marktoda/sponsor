// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {ExecutionLib} from "./lib/ExecutionLib.sol";
import {SelfOperations} from "./base/SelfOperations.sol";
import {Conditions} from "./base/Conditions.sol";
import {Multicall} from "./base/Multicall.sol";
import {Permit2Setup} from "./base/Permit2Setup.sol";
import {ConditionType, Condition, Operation, Execution} from "./base/SponsorStructs.sol";

/// @notice a contract that executes signed user token-oriented operations on their behalf
contract Sponsor is SelfOperations, Conditions, Multicall, Permit2Setup {
    using ExecutionLib for Execution;

    error UserOperationFailed(uint256 i);
    error SponsorOperationFailed(uint256 i);
    error ETHPaymentFailed();

    /// @notice execute the given user execution by spec, verifying specified conditions afterwards
    ///     pay msg.sender for the effort upon successful execution
    /// @param execution the execution to execute
    function execute(Execution calldata execution) external {
        _receiveTokens(execution);
        _executeOperations(execution.operations, true);
        _checkConditions(execution.conditions);
    }

    /// @notice execute the given user execution by spec, verifying specified conditions afterwards
    ///     pay msg.sender for the effort upon successful execution
    ///     allows sponsor to execute further operations to pass user conditions
    /// @param execution the execution to execute
    function execute(Execution calldata execution, Operation[] calldata sponsorOperations) external {
        _receiveTokens(execution);
        _executeOperations(execution.operations, true);

        // execute any sponsor-requested operations
        // these may allow sponsor to help pass user conditions
        // or to claim unswept funds as payment in addition to specified payment
        _executeOperations(sponsorOperations, false);
        _checkConditions(execution.conditions);
    }

    /// @notice receive tokens from the user
    /// @dev also verifies user signature over the execution data
    /// @param execution the execution to receive tokens for
    function _receiveTokens(Execution calldata execution) internal {
        permit2.permitWitnessTransferFrom(
            execution.toPermit(),
            execution.transferDetails(),
            execution.sender,
            execution.hash(),
            ExecutionLib.PERMIT2_EXECUTION_TYPE,
            execution.signature
        );
    }

    /// @notice execute the given operations
    /// @param operations the operations to execute
    /// @param userOperations whether the operations are user operations
    function _executeOperations(Operation[] calldata operations, bool userOperations) internal {
        for (uint256 i = 0; i < operations.length; i++) {
            Operation calldata operation = operations[i];

            bool success;
            // if self-operation, self-delegatecall to preserve call context
            if (operation.to == address(this)) {
                (success,) = address(this).delegatecall(operation.data);
            } else {
                (success,) = operation.to.call(operation.data);
            }

            if (!success) {
                if (userOperations) revert UserOperationFailed(i);
                else revert SponsorOperationFailed(i);
            }
        }
    }

    receive() external payable {}
}
