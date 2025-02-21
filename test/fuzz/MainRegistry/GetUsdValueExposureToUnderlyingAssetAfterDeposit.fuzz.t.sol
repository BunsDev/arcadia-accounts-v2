/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { MainRegistry_Fuzz_Test } from "./_MainRegistry.fuzz.t.sol";

import { StdStorage, stdStorage } from "../../../lib/forge-std/src/Test.sol";

import { RiskConstants } from "../../../src/libraries/RiskConstants.sol";
import { RiskModule } from "../../../src/RiskModule.sol";

/**
 * @notice Fuzz tests for the function "getUsdValueExposureToUnderlyingAssetAfterDeposit" of contract "MainRegistry".
 */
contract GetUsdValueExposureToUnderlyingAssetAfterDeposit_MainRegistry_Fuzz_Test is MainRegistry_Fuzz_Test {
    using stdStorage for StdStorage;
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        MainRegistry_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_getUsdValueExposureToUnderlyingAssetAfterDeposit_NonPricingModule(
        address unprivilegedAddress_,
        address underlyingAsset,
        uint96 underlyingAssetId,
        uint256 exposureAssetToUnderlyingAsset,
        int256 deltaExposureAssetToUnderlyingAsset
    ) public {
        vm.assume(!mainRegistryExtension.isPricingModule(unprivilegedAddress_));

        vm.prank(unprivilegedAddress_);
        vm.expectRevert("MR: Only PriceMod.");
        mainRegistryExtension.getUsdValueExposureToUnderlyingAssetAfterDeposit(
            address(creditorUsd),
            underlyingAsset,
            underlyingAssetId,
            exposureAssetToUnderlyingAsset,
            deltaExposureAssetToUnderlyingAsset
        );
    }

    function testFuzz_Success_getUsdValueExposureToUnderlyingAssetAfterDeposit(
        address upperPricingModule,
        address underlyingAsset,
        uint96 underlyingAssetId,
        uint256 exposureAssetToUnderlyingAsset,
        int256 deltaExposureAssetToUnderlyingAsset,
        uint256 usdValue
    ) public {
        vm.assume(deltaExposureAssetToUnderlyingAsset <= type(int128).max); // MaxExposure.
        vm.assume(deltaExposureAssetToUnderlyingAsset > type(int256).min); // Overflows on inversion.

        mainRegistryExtension.setPricingModuleForAsset(underlyingAsset, address(primaryPricingModule));
        primaryPricingModule.setUsdValue(usdValue);

        vm.prank(users.riskManager);
        mainRegistryExtension.setRiskParametersOfPrimaryAsset(
            address(creditorUsd), underlyingAsset, underlyingAssetId, type(uint128).max, 100, 100
        );

        stdstore.target(address(mainRegistryExtension)).sig(mainRegistryExtension.isPricingModule.selector).with_key(
            address(upperPricingModule)
        ).checked_write(true);

        // Prepare expected internal call.
        bytes memory data = abi.encodeCall(
            primaryPricingModule.processIndirectDeposit,
            (
                address(creditorUsd),
                underlyingAsset,
                underlyingAssetId,
                exposureAssetToUnderlyingAsset,
                deltaExposureAssetToUnderlyingAsset
            )
        );

        vm.prank(upperPricingModule);
        vm.expectCall(address(primaryPricingModule), data);
        uint256 usdExposureAssetToUnderlyingAsset = mainRegistryExtension
            .getUsdValueExposureToUnderlyingAssetAfterDeposit(
            address(creditorUsd),
            underlyingAsset,
            underlyingAssetId,
            exposureAssetToUnderlyingAsset,
            deltaExposureAssetToUnderlyingAsset
        );

        assertEq(usdExposureAssetToUnderlyingAsset, usdValue);
    }
}
