// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IUniswapV3Pool } from "../../../../../../src/pricing-modules/UniswapV3/interfaces/IUniswapV3Pool.sol";

interface IUniswapV3PoolExtension is IUniswapV3Pool {
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

    function maxLiquidityPerTick() external view returns (uint128 maxLiquidityPerTick);

    function token0() external view returns (address token0);

    function token1() external view returns (address token1);

    function fee() external view returns (uint24 fee);
}
