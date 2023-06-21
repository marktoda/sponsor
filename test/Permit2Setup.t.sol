// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ISignatureTransfer} from "permit2/src/interfaces/ISignatureTransfer.sol";
import {Test} from "forge-std/Test.sol";
import {Sponsor} from "../src/Sponsor.sol";
import {MockSwap} from "./util/MockSwap.sol";
import {Execution, Condition, ConditionType, Operation} from "../src/base/SponsorStructs.sol";
import {MockERC20} from "./util/MockERC20.sol";

contract Permit2Setup is Test {
    Sponsor sponsor;
    MockERC20 token;
    uint256 privateKey;
    address owner;
    address permit2;

    bytes32 constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function setUp() public {
        token = new MockERC20("Test", "TEST");
        privateKey = 0xabcd;
        owner = vm.addr(privateKey);
        token.mint(owner, 10 ether);
        sponsor = new Sponsor();
        permit2 = address(sponsor.permit2());
    }

    function testPermit2Setup() public {
        assertEq(token.allowance(owner, permit2), 0);
        (uint8 v, bytes32 r, bytes32 s) = getPermit();
        sponsor.permit2Setup(address(token), owner, 1 ether, block.timestamp, v, r, s);
        assertEq(token.allowance(owner, permit2), 1 ether);
    }

    function testPermit2SetupIfNecessary() public {
        assertEq(token.allowance(owner, permit2), 0);
        (uint8 v, bytes32 r, bytes32 s) = getPermit();
        sponsor.permit2SetupIfNecessary(address(token), owner, 1 ether, block.timestamp, v, r, s);
        assertEq(token.allowance(owner, permit2), 1 ether);

        (v, r, s) = getPermit();
        sponsor.permit2SetupIfNecessary(address(token), owner, 1 ether, block.timestamp, v, r, s);
        // shouldnt permit again
        assertEq(token.allowance(owner, permit2), 1 ether);
    }

    function getPermit() internal view returns (uint8 v, bytes32 r, bytes32 s) {
        (v, r, s) = vm.sign(
            privateKey,
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    token.DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, permit2, 1 ether, 0, block.timestamp))
                )
            )
        );
    }
}
