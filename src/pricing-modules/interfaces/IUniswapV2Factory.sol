/**
 * Created by Arcadia Finance
 * https://www.arcadia.finance
 *
 * SPDX-License-Identifier: MIT
 */
pragma solidity 0.8.19;

interface IUniswapV2Factory {
    function feeTo() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address);
}
