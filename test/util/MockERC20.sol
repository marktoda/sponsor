// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol, 18) {}

    function mint(address who, uint256 amount) external {
        _mint(who, amount);
    }
}
