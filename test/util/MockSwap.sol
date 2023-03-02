// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MockSwap {
    constructor() {}

    // swap 1:1
    function swap(ERC20 tokenIn, uint256 amountIn, ERC20 tokenOut) external {
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountIn);
    }

    function swapForETH(ERC20 tokenIn, uint256 amountIn) external {
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        (bool success,) = msg.sender.call{value: amountIn}("");
        require(success, "MockSwap: ETH transfer failed");
    }

    receive() external payable {}
}
