// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ECDSA} from "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "permit2/src/EIP712.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {Execution, Condition, Operation} from "../../src/base/SponsorStructs.sol";
import {ExecutionLib} from "../../src/lib/ExecutionLib.sol";

struct UnsignedExecution {
    ISignatureTransfer.TokenPermissions[] tokens;
    Operation[] operations;
    Condition[] conditions;
    address sender;
    uint256 nonce;
    uint256 deadline;
}

contract PermitSignatures is Test {
    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256("PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    bytes32 constant FULL_EXECUTION_TYPEHASH = keccak256(
        abi.encodePacked(
            "PermitBatchWitnessTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline,",
            ExecutionLib.PERMIT2_EXECUTION_TYPE
        )
    );

    ISignatureTransfer immutable permit2 = ISignatureTransfer(0x000000000022D473030F116dDEE9F6B43aC78BA3);

    function signExecution(UnsignedExecution memory execution, uint256 privateKey, address spender)
        internal
        view
        returns (Execution memory result)
    {
        ISignatureTransfer.PermitBatchTransferFrom memory permit = ISignatureTransfer.PermitBatchTransferFrom({
            permitted: execution.tokens,
            nonce: execution.nonce,
            deadline: execution.deadline
        });

        result = Execution({
            tokens: execution.tokens,
            operations: execution.operations,
            conditions: execution.conditions,
            sender: execution.sender,
            nonce: execution.nonce,
            deadline: execution.deadline,
            signature: new bytes(0)
        });

        bytes memory sig = getPermitBatchWitnessSignature(
            permit,
            spender,
            privateKey,
            FULL_EXECUTION_TYPEHASH,
            ExecutionLib.hash(result),
            EIP712(address(permit2)).DOMAIN_SEPARATOR()
        );
        result.signature = sig;
    }

    function getPermitBatchWitnessSignature(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        address spender,
        uint256 privateKey,
        bytes32 typeHash,
        bytes32 witness,
        bytes32 domainSeparator
    ) internal pure returns (bytes memory sig) {
        bytes32[] memory tokenPermissions = new bytes32[](permit.permitted.length);
        for (uint256 i = 0; i < permit.permitted.length; ++i) {
            tokenPermissions[i] = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permit.permitted[i]));
        }

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        typeHash,
                        keccak256(abi.encodePacked(tokenPermissions)),
                        spender,
                        permit.nonce,
                        permit.deadline,
                        witness
                    )
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);
        return bytes.concat(r, s, bytes1(v));
    }

    function defaultERC20PermitMultiple(address[] memory tokens, uint256 nonce)
        internal
        view
        returns (ISignatureTransfer.PermitBatchTransferFrom memory)
    {
        ISignatureTransfer.TokenPermissions[] memory permitted =
            new ISignatureTransfer.TokenPermissions[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ++i) {
            permitted[i] = ISignatureTransfer.TokenPermissions({token: tokens[i], amount: 10 ** 18});
        }
        return ISignatureTransfer.PermitBatchTransferFrom({
            permitted: permitted,
            nonce: nonce,
            deadline: block.timestamp + 100
        });
    }
}
