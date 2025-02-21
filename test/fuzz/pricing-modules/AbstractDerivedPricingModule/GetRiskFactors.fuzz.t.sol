/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { AbstractDerivedPricingModule_Fuzz_Test } from "./_AbstractDerivedPricingModule.fuzz.t.sol";

import { RiskConstants } from "../../../../src/libraries/RiskConstants.sol";
import { Utils } from "../../../utils/Utils.sol";

/**
 * @notice Fuzz tests for the function "getRiskFactors" of contract "AbstractDerivedPricingModule".
 */
contract GetRiskFactors_AbstractDerivedPricingModule_Fuzz_Test is AbstractDerivedPricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        AbstractDerivedPricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Success_getRiskFactors(
        address creditor,
        address asset,
        uint96 assetId,
        uint16 riskFactor,
        address[2] memory underlyingAssets,
        uint256[2] memory underlyingAssetIds,
        uint16[2] memory collateralFactors,
        uint16[2] memory liquidationFactors
    ) public {
        // Given: id's are smaller or equal to type(uint96).max.
        underlyingAssetIds[0] = bound(underlyingAssetIds[0], 0, type(uint96).max);
        underlyingAssetIds[1] = bound(underlyingAssetIds[1], 0, type(uint96).max);

        // And: Risk factors are below max risk factor.
        riskFactor = uint16(bound(riskFactor, 0, RiskConstants.RISK_FACTOR_UNIT));
        collateralFactors[0] = uint16(bound(collateralFactors[0], 0, RiskConstants.RISK_FACTOR_UNIT));
        collateralFactors[1] = uint16(bound(collateralFactors[1], 0, RiskConstants.RISK_FACTOR_UNIT));
        liquidationFactors[0] = uint16(bound(liquidationFactors[0], 0, RiskConstants.RISK_FACTOR_UNIT));
        liquidationFactors[1] = uint16(bound(liquidationFactors[1], 0, RiskConstants.RISK_FACTOR_UNIT));

        // And: Underlying assets are in primaryPricingModule.
        mainRegistryExtension.setPricingModuleForAsset(underlyingAssets[0], address(primaryPricingModule));
        mainRegistryExtension.setPricingModuleForAsset(underlyingAssets[1], address(primaryPricingModule));
        vm.startPrank(address(mainRegistryExtension));
        primaryPricingModule.setRiskParameters(
            creditor, underlyingAssets[0], underlyingAssetIds[0], 0, collateralFactors[0], liquidationFactors[0]
        );
        primaryPricingModule.setRiskParameters(
            creditor, underlyingAssets[1], underlyingAssetIds[1], 0, collateralFactors[1], liquidationFactors[1]
        );
        vm.stopPrank();

        // And: Asset is in derivedPricingModule.
        derivedPricingModule.addAsset(
            asset,
            assetId,
            Utils.castArrayStaticToDynamic(underlyingAssets),
            Utils.castArrayStaticToDynamic(underlyingAssetIds)
        );
        vm.prank(address(mainRegistryExtension));
        derivedPricingModule.setRiskParameters(creditor, 0, riskFactor);

        // When: "getRiskFactors" is called.
        (uint16 actualCollateralFactor, uint16 actualLiquidationFactor) =
            derivedPricingModule.getRiskFactors(creditor, asset, assetId);

        // Then: Transaction returns correct risk factors.
        uint256 expectedCollateralFactor =
            collateralFactors[0] < collateralFactors[1] ? collateralFactors[0] : collateralFactors[1];
        expectedCollateralFactor = expectedCollateralFactor * riskFactor / RiskConstants.RISK_FACTOR_UNIT;
        assertEq(actualCollateralFactor, expectedCollateralFactor);

        uint256 expectedLiquidationFactor =
            liquidationFactors[0] < liquidationFactors[1] ? liquidationFactors[0] : liquidationFactors[1];
        expectedLiquidationFactor = expectedLiquidationFactor * riskFactor / RiskConstants.RISK_FACTOR_UNIT;
        assertEq(actualLiquidationFactor, expectedLiquidationFactor);
    }
}
