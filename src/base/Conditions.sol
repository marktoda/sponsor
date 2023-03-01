// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Condition, ConditionType} from "./SponsorStructs.sol";

/// @notice operations that can be performed on the router contract itself
abstract contract Conditions {
    error ConditionCallFailed(uint256 index);
    error ConditionFailed(uint256 index);

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
