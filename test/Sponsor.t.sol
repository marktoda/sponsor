// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Sponsor} from "../src/Sponsor.sol";
import {DeployPermit2} from "./util/DeployPermit2.sol";
import {Execution, Condition, ConditionType, Operation} from "../src/base/SponsorStructs.sol";
import {MockERC20} from "./util/MockERC20.sol";
import {PermitSignatures, UnsignedExecution} from "./util/PermitSignatures.sol";

contract SponsorTest is Test, DeployPermit2, PermitSignatures {
    error ConditionCallFailed(uint256 index);
    error ConditionFailed(uint256 index);

    address constant recipient = address(1);
    uint256 constant senderPk = 0x1234;
    address sender;
    address operator;
    Sponsor sponsor;
    MockERC20 tokenA;
    MockERC20 tokenB;

    function setUp() public {
        sender = vm.addr(senderPk);
        operator = makeAddr("operator");
        deployPermit2();
        sponsor = new Sponsor();
        tokenA = new MockERC20("TokenA", "TA");
        tokenB = new MockERC20("TokenB", "TB");
        tokenA.mint(sender, 100 ether);
        vm.prank(sender);
        tokenA.approve(address(permit2), type(uint256).max);
        tokenB.mint(sender, 100 ether);
        vm.prank(sender);
        tokenB.approve(address(permit2), type(uint256).max);
    }

    function testSponsorSimpleTransfer() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();
        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));

        vm.prank(operator);
        sponsor.execute(execution);

        assertEq(tokenA.balanceOf(sender), 99 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(operator), 0.1 ether);
    }

    function testSponsorSimpleTwoTransfers() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();

        ISignatureTransfer.TokenPermissions[] memory tokens = new ISignatureTransfer.TokenPermissions[](2);
        tokens[0] = ISignatureTransfer.TokenPermissions({token: address(tokenA), amount: 1 ether});
        tokens[1] = ISignatureTransfer.TokenPermissions({token: address(tokenB), amount: 1 ether});

        Operation[] memory operations = new Operation[](2);
        operations[0] = Operation({
            to: address(tokenA),
            data: abi.encodeWithSelector(ERC20.transfer.selector, recipient, 0.9 ether)
        });

        operations[1] =
            Operation({to: address(tokenB), data: abi.encodeWithSelector(ERC20.transfer.selector, recipient, 1 ether)});


        unsigned.tokens = tokens;
        unsigned.operations = operations;

        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));

        vm.prank(operator);
        sponsor.execute(execution);

        assertEq(tokenA.balanceOf(sender), 99 ether);
        assertEq(tokenA.balanceOf(recipient), 0.9 ether);
        assertEq(tokenA.balanceOf(operator), 0.1 ether);

        assertEq(tokenB.balanceOf(sender), 99 ether);
        assertEq(tokenB.balanceOf(recipient), 1 ether);
        assertEq(tokenB.balanceOf(operator), 0 ether);
    }

    function testSponsorSimpleTransferFailingCondition() public {
        UnsignedExecution memory unsigned = buildSimpleExecution();

        Condition[] memory conditions = new Condition[](1);
        conditions[0] = Condition({
            toCall: address(tokenA),
            data: abi.encodeWithSignature("balanceOf(address)", sender),
            conditionType: ConditionType.GREATER_THAN,
            check: abi.encode(100 ether)
        });
        unsigned.conditions = conditions;

        Execution memory execution = signExecution(unsigned, senderPk, address(sponsor));

        vm.prank(operator);
        vm.expectRevert(abi.encodeWithSelector(ConditionFailed.selector, 0));
        sponsor.execute(execution);
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
}
