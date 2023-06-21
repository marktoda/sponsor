// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";

enum ConditionType {
    EQUAL,
    NOT_EQUAL,
    GREATER_THAN,
    LESS_THAN,
    GREATER_THAN_OR_EQUAL,
    LESS_THAN_OR_EQUAL,
    TRUE,
    FALSE
}

struct Condition {
    ConditionType conditionType;
    address toCall;
    bytes data;
    bytes check;
}

struct Operation {
    address to;
    bytes data;
}

struct Execution {
    ISignatureTransfer.TokenPermissions[] tokens;
    Operation[] operations;
    Condition[] conditions;
    address sender;
    uint256 nonce;
    uint256 deadline;
    bytes signature;
}
