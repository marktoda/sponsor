# Sponsor

Simple sponsored transactions framework using Permit2 for batch token transfers and signature verification.

## Execution specification

Users specify their sponsored execution using the following parameters:


```solidity
struct Execution {
    ISignatureTransfer.TokenPermissions[] tokens;
    ISignatureTransfer.TokenPermissions payment;
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

**payment**

The ERC20 token and amount that the user is willing to pay the sponsor operator in return for execution. This should generally cover gas costs and a tip for the service. Payment can also be made in ETH using address(0) as token, though the ETH must be acquired through operations.

Any payment is transferred directly from the sponsor contract, so the payment assets must be included in `token`, or acquired through `operations`.

**operations**

The operations that will be executed. These are made as external calls to the specified address with the specified data. I.e. user can specify simple transfers of tokens, swaps on AMMS, deposits into lending markets etc.

There are some built-in operations to simplify common flows:
- sweep: sweep the full balance of a given token to the given recipient
- sweepETH: sweep the full balance of ETH to the given recipient


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


**THIS IS EXPERIMENTAL, UNAUDITED CODE -- DO NOT USE IN PRODUCTION**
