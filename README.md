# Sponsor

Simple sponsored transactions framework using Permit2 for batch token transfers and signature verification.

## Execution specification

Users specify their sponsored execution using the following parameters:


```solidity
struct Execution {
    ISignatureTransfer.TokenPermissions[] tokens;
    Operation[] operations;
    Condition[] conditions;
    address sender;
    uint256 nonce;
    uint256 deadline;
    bytes signature;
}

```

**tokens**

The ERC20 tokens and amounts that will be used for the execution. These are transferred from the user using permit2 into the sponsor contract to be used for any _operations_.

**operations**

The operations that will be executed. These are made as external calls to the specified address with the specified data. I.e. user can specify simple transfers of tokens, swaps on AMMS, deposits into lending markets etc.

There are some built-in operations to simplify common flows:
- sweep: sweep the full balance of a given currency to the given recipient
- tip: pay some amount of a given currency to the operator who submitted the execution
- tipEscalating: pay some amount defined by a fee escalator of a given currency to the operator who submitted the execution
    - Escalator is defined by start/end timestamps and amounts. The amount increases linearly from startAmount to endAmount over startTime to endTime.
    - This may be used to create an auction for relaying executions

**conditions**

Any conditions that the user wants to check _after_ all operations are finished. I.e. check to ensure the user balances of a given token exceed a certain amount. A simple scripting language is used for defining conditions.

- conditionType: enum of the type of check to perform
- toCall: the contract to staticcall for a value to condition against
- data: the data to call the given contract with
- check: the value to check against

ex: assert(tokenA.balanceOf(user) >= 1000) would be defined as:
- condition: ConditionType.GREATER_THAN_OR_EQUAL
- toCall: tokenA
- data: abi.encodeWithSignature("balanceOf(address)", user)
- check: abi.encode(1000)

**sender**

The address of the signer

**nonce**

The nonce of the signer using the permit2 unordered nonce scheme

**deadline**

The timestamp deadline for the signature validity

**signature**

The sender signature in joined signature format, or EIP-1271 signature data


## Permit2 Setup
In order to submit executions through Sponsor, users must have first approved Permit2 for any tokens they wish to use.

Sponsor includes a "Permit2 setup" set of utility functions in base/Permit2Setup.sol which can be used to streamline this process. If the ERC20 token that is being onboarded supports native permit, these functions can be called in the same transaction as the execution itself to have a fully gasless onboarding experience.

Operators can use the built-in multicall function to batch the Permit2Setup call(s) with execution itself.

**THIS IS EXPERIMENTAL, UNAUDITED CODE -- DO NOT USE IN PRODUCTION**
