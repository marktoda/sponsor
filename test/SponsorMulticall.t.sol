// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Sponsor} from "../src/Sponsor.sol";
import {MockSwap} from "./util/MockSwap.sol";
import {DeployPermit2} from "./util/DeployPermit2.sol";
import {SelfOperations} from "../src/base/SelfOperations.sol";
import {Execution, Condition, ConditionType, Operation} from "../src/base/SponsorStructs.sol";
import {MockERC20} from "./util/MockERC20.sol";
import {PermitSignatures, UnsignedExecution} from "./util/PermitSignatures.sol";

contract SponsorMulticallTest is Test, DeployPermit2, PermitSignatures {
    error TransactionExpired();
    error InvalidBlockHash();

    bytes4 constant EXECUTE_SELECTOR = bytes4(
        keccak256(
            "execute(((address,uint256)[],(address,uint256),(address,bytes)[],(uint8,address,bytes,bytes)[],address,uint256,uint256,bytes))"
        )
    );
    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    address constant recipient = address(1);
    uint256 constant senderPk = 0x1234;
    address sender;
    address operator;
    Sponsor sponsor;
    MockERC20 tokenA;
    MockERC20 tokenB;
    MockSwap mockSwap;

    function setUp() public {
        sender = vm.addr(senderPk);
        operator = makeAddr("operator");
        deployPermit2();
        sponsor = new Sponsor();
        tokenA = new MockERC20("TokenA", "TA");
        tokenB = new MockERC20("TokenB", "TB");
        tokenA.mint(sender, 100 ether);
        tokenB.mint(sender, 100 ether);
        mockSwap = new MockSwap();
        tokenA.mint(address(mockSwap), 1 ether);
        tokenB.mint(address(mockSwap), 1 ether);
        (bool success,) = address(mockSwap).call{value: 1 ether}("");
        require(success, "MockSwap: ETH transfer failed");
    }

    function testSponsorPermitAndSimpleTransferMulticall() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();
        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));
        (uint8 v, bytes32 r, bytes32 s) = getPermit(tokenA);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            sponsor.permit2Setup.selector, address(tokenA), sender, 1 ether, block.timestamp, v, r, s
        );
        calls[1] = abi.encodeWithSelector(EXECUTE_SELECTOR, execution);

        vm.prank(operator);
        sponsor.multicall(calls);

        assertEq(tokenA.balanceOf(sender), 99 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(operator), 0.1 ether);
    }

    function testSponsorPermitAndSimpleTransferMulticallWithDeadline() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();
        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));
        (uint8 v, bytes32 r, bytes32 s) = getPermit(tokenA);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            sponsor.permit2Setup.selector, address(tokenA), sender, 1 ether, block.timestamp, v, r, s
        );
        calls[1] = abi.encodeWithSelector(EXECUTE_SELECTOR, execution);

        vm.prank(operator);
        sponsor.multicall(block.timestamp + 1, calls);

        assertEq(tokenA.balanceOf(sender), 99 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(operator), 0.1 ether);
    }

    function testSponsorPermitAndSimpleTransferMulticallWithDeadlineExpired() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();
        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));
        (uint8 v, bytes32 r, bytes32 s) = getPermit(tokenA);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            sponsor.permit2Setup.selector, address(tokenA), sender, 1 ether, block.timestamp, v, r, s
        );
        calls[1] = abi.encodeWithSelector(EXECUTE_SELECTOR, execution);

        vm.prank(operator);
        vm.expectRevert(TransactionExpired.selector);
        sponsor.multicall(block.timestamp - 1, calls);
    }

    function testSponsorPermitAndSimpleTransferMulticallWithBlockHash() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();
        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));
        (uint8 v, bytes32 r, bytes32 s) = getPermit(tokenA);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            sponsor.permit2Setup.selector, address(tokenA), sender, 1 ether, block.timestamp, v, r, s
        );
        calls[1] = abi.encodeWithSelector(EXECUTE_SELECTOR, execution);

        vm.prank(operator);
        sponsor.multicall(blockhash(block.number - 1), calls);

        assertEq(tokenA.balanceOf(sender), 99 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(operator), 0.1 ether);
    }

    function testSponsorPermitAndSimpleTransferMulticallWithBlockHashInvalid() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();
        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));
        (uint8 v, bytes32 r, bytes32 s) = getPermit(tokenA);

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            sponsor.permit2Setup.selector, address(tokenA), sender, 1 ether, block.timestamp, v, r, s
        );
        calls[1] = abi.encodeWithSelector(EXECUTE_SELECTOR, execution);

        vm.prank(operator);
        vm.expectRevert(InvalidBlockHash.selector);
        sponsor.multicall(keccak256(hex"10"), calls);
    }

    function buildSimpleExecution() internal view returns (UnsignedExecution memory unsigned) {
        ISignatureTransfer.TokenPermissions[] memory tokens = new ISignatureTransfer.TokenPermissions[](1);
        tokens[0] = ISignatureTransfer.TokenPermissions({token: address(tokenA), amount: 1 ether});

        // pay operator 0.1 tokenB for their effort and gas
        ISignatureTransfer.TokenPermissions memory payment =
            ISignatureTransfer.TokenPermissions({token: address(tokenA), amount: 0.1 ether});

        Operation[] memory operations = new Operation[](1);
        // transfer 0.9 ether to recipient
        operations[0] = Operation({
            to: address(tokenA),
            data: abi.encodeWithSelector(ERC20.transfer.selector, recipient, 0.9 ether)
        });

        Condition[] memory conditions = new Condition[](0);

        unsigned = UnsignedExecution({
            tokens: tokens,
            payment: payment,
            operations: operations,
            conditions: conditions,
            sender: sender,
            nonce: 0,
            deadline: block.timestamp + 100
        });
    }

    function getPermit(ERC20 token) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        (v, r, s) = vm.sign(
            senderPk,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, sender, permit2, 1 ether, 0, block.timestamp))
                )
            )
        );
    }
}
