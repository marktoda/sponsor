// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {ExecutionLib} from "./lib/ExecutionLib.sol";
import {ConditionType, Condition, Operation, Execution} from "./base/SponsorStructs.sol";

contract Sponsor {
    using ExecutionLib for Execution;

    error ConditionCallFailed(uint256 index);
    error ConditionFailed(uint256 index);
    error UserOperationFailed();
    error SponsorOperationFailed();

    ISignatureTransfer constant permit2 = ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    address constant PREFETCHED_CONDITION = address(0);

    /// @notice execute the given user execution
    function execute(Execution calldata execution, Operation[] calldata sponsorOperations) external {
        permit2.permitWitnessTransferFrom(
            execution.toPermit(),
            execution.transferDetails(),
            execution.sender,
            execution.hash(),
            ExecutionLib.PERMIT2_EXECUTION_TYPE,
            execution.signature
        );

        // execute any user-requested operations
        for (uint256 i = 0; i < execution.operations.length; i++) {
            Operation calldata operation = execution.operations[i];
            (bool success, ) = operation.to.call(operation.data);
            if (!success) {
                revert UserOperationFailed();
            }
        }

        // execute any sponsor-requested operations
        // these can be used to claim leftover tokens as payment
        // or to meet user conditions
        for (uint256 i = 0; i < sponsorOperations.length; i++) {
            Operation calldata operation = sponsorOperations[i];
            (bool success, ) = operation.to.call(operation.data);
            if (!success) {
                revert SponsorOperationFailed();
            }
        }

        _checkConditions(execution.conditions);
    }

    /// @dev check the conditions
    function _checkConditions(Condition[] calldata conditions) internal view {
        for (uint256 i = 0; i < conditions.length; i++) {
            Condition calldata condition = conditions[i];

            (bool success, bytes memory data) = condition.toCall.staticcall(condition.data);
            if (!success) {
                revert ConditionCallFailed(i);
            }

            if (condition.conditionType == ConditionType.EQUAL) {
                uint256 value = abi.decode(data, (uint256));
                uint256 check = abi.decode(condition.check, (uint256));
                if (value != check) {
                    revert ConditionFailed(i);
                }
            } else if (condition.conditionType == ConditionType.NOT_EQUAL) {
                uint256 value = abi.decode(data, (uint256));
                uint256 check = abi.decode(condition.check, (uint256));
                if (value == check) {
                    revert ConditionFailed(i);
                }
            } else if (condition.conditionType == ConditionType.GREATER_THAN) {
                uint256 value = abi.decode(data, (uint256));
                uint256 check = abi.decode(condition.check, (uint256));
                if (value <= check) {
                    revert ConditionFailed(i);
                }
            } else if (condition.conditionType == ConditionType.LESS_THAN) {
                uint256 value = abi.decode(data, (uint256));
                uint256 check = abi.decode(condition.check, (uint256));
                if (value >= check) {
                    revert ConditionFailed(i);
                }
            } else if (condition.conditionType == ConditionType.GREATER_THAN_OR_EQUAL) {
                uint256 value = abi.decode(data, (uint256));
                uint256 check = abi.decode(condition.check, (uint256));
                if (value < check) {
                    revert ConditionFailed(i);
                }
            } else if (condition.conditionType == ConditionType.LESS_THAN_OR_EQUAL) {
                uint256 value = abi.decode(data, (uint256));
                uint256 check = abi.decode(condition.check, (uint256));
                if (value > check) {
                    revert ConditionFailed(i);
                }
            } else if (condition.conditionType == ConditionType.TRUE) {
                bool value = abi.decode(data, (bool));
                if (!value) {
                    revert ConditionFailed(i);
                }
            } else if (condition.conditionType == ConditionType.FALSE) {
                bool value = abi.decode(data, (bool));
                if (value) {
                    revert ConditionFailed(i);
                }
            }
        }
    }
}
