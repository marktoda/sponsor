// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {SelfOperations} from "../src/base/SelfOperations.sol";
import {MockEscalator} from "./util/MockEscalator.sol";

contract EscalatorTest is Test {
    MockEscalator escalator;

    function setUp() public {
        escalator = new MockEscalator();
    }

    function testNoEscalation(uint256 amount, uint256 startTime, uint256 endTime) public {
        vm.assume(endTime >= startTime);
        assertEq(escalator.resolve(startTime, endTime, amount, amount), amount);
    }

    function testNoEscalationYet() public {
        vm.warp(80);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 1 ether);

        vm.warp(100);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 1 ether);
    }

    function testEscalation() public {
        vm.warp(100);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 1 ether);
        vm.warp(150);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 1.5 ether);
        vm.warp(180);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 1.8 ether);
        vm.warp(190);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 1.9 ether);
        vm.warp(200);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 2 ether);
    }

    function testEscalationOver() public {
        vm.warp(205);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 2 ether);
        vm.warp(10000);
        assertEq(escalator.resolve(100, 200, 1 ether, 2 ether), 2 ether);
    }

    function testEscalationBounded(uint256 startTime, uint256 endTime, uint256 startAmount, uint256 endAmount) public {
        vm.assume(endAmount > startAmount);
        vm.assume(endTime >= startTime);

        uint256 result = escalator.resolve(startTime, endTime, startAmount, endAmount);
        assertGe(result, startAmount);
        assertLe(result, endAmount);
    }

    function testEscalationInvalidTimes(uint256 startTime, uint256 endTime, uint256 startAmount, uint256 endAmount)
        public
    {
        vm.assume(endAmount > startAmount);
        vm.assume(endTime < startTime);

        vm.expectRevert(SelfOperations.InvalidEscalatorTimes.selector);
        escalator.resolve(startTime, endTime, startAmount, endAmount);
    }

    function testEscalationInvalidAmounts(uint256 startTime, uint256 endTime, uint256 startAmount, uint256 endAmount)
        public
    {
        vm.assume(endAmount < startAmount);
        vm.assume(endTime > startTime);

        vm.expectRevert(SelfOperations.InvalidEscalatorAmounts.selector);
        escalator.resolve(startTime, endTime, startAmount, endAmount);
    }
}
