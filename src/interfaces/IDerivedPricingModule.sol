/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity 0.8.19;

interface IDerivedPricingModule {
    /**
     * @notice Sets the risk parameters for an asset for a given creditor.
     * @param creditor The contract address of the creditor.
     * @param maxUsdExposureProtocol_ The maximum usd exposure of the protocol for each creditor, denominated in USD with 18 decimals precision.
     * @param riskFactor The risk factor of the asset for the creditor, 2 decimals precision.
     */
    function setRiskParameters(address creditor, uint128 maxUsdExposureProtocol_, uint16 riskFactor) external;
}
