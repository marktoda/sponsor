// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {SelfOperations} from "../../src/base/SelfOperations.sol";

contract MockEscalator is SelfOperations {
    function resolve(uint256 startTime, uint256 endTime, uint256 startAmount, uint256 endAmount)
        external
        view
        returns (uint256)
    {
        return resolveEscalator(startTime, endTime, startAmount, endAmount);
    }
}
