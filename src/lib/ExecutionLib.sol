// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {ConditionType, Condition, Operation, Execution} from "../base/SponsorStructs.sol";

library ExecutionLib {
    bytes private constant OPERATION_TYPE = "Operation(address to,bytes data)";

    bytes32 private constant OPERATION_TYPE_HASH = keccak256(OPERATION_TYPE);

    bytes private constant CONDITION_TYPE = "Condition(uint8 conditionType,address toCall,bytes data,bytes check)";

    bytes32 private constant CONDITION_TYPE_HASH = keccak256(CONDITION_TYPE);

    bytes private constant EXECUTION_TYPE =
        abi.encodePacked("Execution(Operation[] operations,Condition[] conditions)", CONDITION_TYPE, OPERATION_TYPE);

    bytes32 private constant EXECUTION_TYPE_HASH = keccak256(EXECUTION_TYPE);

    string internal constant PERMIT2_EXECUTION_TYPE = string(abi.encodePacked("Execution witness)", EXECUTION_TYPE));

    function hash(Operation memory operation) private pure returns (bytes32) {
        return keccak256(abi.encode(OPERATION_TYPE_HASH, operation.to, keccak256(operation.data)));
    }

    function hash(Operation[] memory operations) private pure returns (bytes32) {
        bytes32[] memory operationHashes = new bytes32[](operations.length);
        unchecked {
            for (uint256 i = 0; i < operations.length; i++) {
                operationHashes[i] = hash(operations[i]);
            }
        }
        return keccak256(abi.encodePacked(operationHashes));
    }

    function hash(Condition memory condition) private pure returns (bytes32) {
        return keccak256(
            abi.encode(
                CONDITION_TYPE_HASH,
                condition.conditionType,
                condition.toCall,
                keccak256(condition.data),
                keccak256(condition.check)
            )
        );
    }

    function hash(Condition[] memory conditions) private pure returns (bytes32) {
        bytes32[] memory conditionHashes = new bytes32[](conditions.length);
        unchecked {
            for (uint256 i = 0; i < conditions.length; i++) {
                conditionHashes[i] = hash(conditions[i]);
            }
        }
        return keccak256(abi.encodePacked(conditionHashes));
    }

    function hash(Execution memory execution) internal pure returns (bytes32) {
        return keccak256(abi.encode(EXECUTION_TYPE_HASH, hash(execution.operations), hash(execution.conditions)));
    }

    function toPermit(Execution memory execution)
        internal
        pure
        returns (ISignatureTransfer.PermitBatchTransferFrom memory permit)
    {
        return ISignatureTransfer.PermitBatchTransferFrom({
            permitted: execution.tokens,
            nonce: execution.nonce,
            deadline: execution.deadline
        });
    }

    function transferDetails(Execution memory execution)
        internal
        view
        returns (ISignatureTransfer.SignatureTransferDetails[] memory details)
    {
        details = new ISignatureTransfer.SignatureTransferDetails[](execution.tokens.length);
        for (uint256 i = 0; i < execution.tokens.length; i++) {
            details[i] = ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: execution.tokens[i].amount
            });
        }
    }
}
