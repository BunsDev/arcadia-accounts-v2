/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { IERC20 } from "../../../src/interfaces/IERC20.sol";

contract MultiActionMock {
    function swapAssets(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut) public {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);
    }

    function assetSink(address token, uint256 amount) public {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function assetSource(address token, uint256 amount) public {
        IERC20(token).transfer(msg.sender, amount);
    }
}
