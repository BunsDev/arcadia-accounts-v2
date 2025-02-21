/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { MainRegistry_Fuzz_Test } from "./_MainRegistry.fuzz.t.sol";

import { RiskConstants } from "../../../src/libraries/RiskConstants.sol";

/**
 * @notice Fuzz tests for the function "setRiskParametersOfPrimaryAsset" of contract "MainRegistry".
 */
contract SetRiskParametersOfPrimaryAsset_MainRegistry_Fuzz_Test is MainRegistry_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        MainRegistry_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_setRiskParametersOfPrimaryAsset_NonRiskManager(
        address unprivilegedAddress_,
        address asset,
        uint96 assetId,
        uint128 maxExposure,
        uint16 collateralFactor,
        uint16 liquidationFactor
    ) public {
        vm.assume(unprivilegedAddress_ != users.riskManager);

        vm.startPrank(unprivilegedAddress_);
        vm.expectRevert("MR_SRPPA: Not Authorized");
        mainRegistryExtension.setRiskParametersOfPrimaryAsset(
            address(creditorUsd), asset, assetId, maxExposure, collateralFactor, liquidationFactor
        );
        vm.stopPrank();
    }

    function testFuzz_Success_setRiskParametersOfPrimaryAsset(
        address asset,
        uint96 assetId,
        uint128 maxExposure,
        uint16 collateralFactor,
        uint16 liquidationFactor
    ) public {
        collateralFactor = uint16(bound(collateralFactor, 0, RiskConstants.RISK_FACTOR_UNIT));
        liquidationFactor = uint16(bound(liquidationFactor, 0, RiskConstants.RISK_FACTOR_UNIT));

        mainRegistryExtension.setPricingModuleForAsset(asset, address(primaryPricingModule));

        vm.prank(users.riskManager);
        mainRegistryExtension.setRiskParametersOfPrimaryAsset(
            address(creditorUsd), asset, assetId, maxExposure, collateralFactor, liquidationFactor
        );

        bytes32 assetKey = bytes32(abi.encodePacked(assetId, asset));
        (, uint128 actualMaxExposure, uint16 actualCollateralFactor, uint16 actualLiquidationFactor) =
            primaryPricingModule.riskParams(address(creditorUsd), assetKey);
        assertEq(actualMaxExposure, maxExposure);
        assertEq(actualCollateralFactor, collateralFactor);
        assertEq(actualLiquidationFactor, liquidationFactor);
    }
}
