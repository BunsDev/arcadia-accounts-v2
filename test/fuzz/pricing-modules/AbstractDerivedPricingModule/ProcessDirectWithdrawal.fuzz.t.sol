/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { Constants, AbstractDerivedPricingModule_Fuzz_Test } from "./_AbstractDerivedPricingModule.fuzz.t.sol";

import { PricingModule } from "../../../../src/pricing-modules/AbstractPricingModule_New.sol";

/**
 * @notice Fuzz tests for the "processDirectWithdrawal" of contract "AbstractDerivedPricingModule".
 * @notice Tests performed here will validate the recursion flow of derived pricing modules.
 * Testing for conversion rates and getValue() will be done in pricing modules testing separately.
 */
contract ProcessDirectWithdrawal_AbstractDerivedPricingModule_Fuzz_Test is AbstractDerivedPricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        AbstractDerivedPricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_processDirectWithdrawal_NonMainRegistry(
        address unprivilegedAddress_,
        address asset,
        uint256 id,
        uint128 amount
    ) public {
        vm.assume(unprivilegedAddress_ != address(mainRegistryExtension_New));

        vm.startPrank(unprivilegedAddress_);
        vm.expectRevert("APM: ONLY_MAIN_REGISTRY");
        derivedPricingModule.processDirectWithdrawal(asset, id, amount);
        vm.stopPrank();
    }

    function testFuzz_Success_processDirectWithdrawal(
        DerivedPricingModuleProtocolState memory protocolState,
        DerivedPricingModuleAssetState memory assetState,
        UnderlyingPricingModuleState memory underlyingPMState,
        uint256 id,
        uint256 amount
    ) public {
        // Given: No overflow on cast amount.
        amount = bound(amount, 0, uint256(type(int256).max));

        uint256 exposureAsset;
        if (amount < assetState.exposureAssetLast) exposureAsset = assetState.exposureAssetLast - amount;

        // And: No overflow on exposureAssetToUnderlyingAsset.
        if (exposureAsset != 0) {
            assetState.conversionRate =
                bound(assetState.conversionRate, 0, uint256(type(uint128).max) * 1e18 / exposureAsset);
        }

        // And: usdValueExposureToUnderlyingAsset does not overflow.
        underlyingPMState.usdValueExposureToUnderlyingAsset =
            bound(underlyingPMState.usdValueExposureToUnderlyingAsset, 0, type(uint128).max);

        // And: exposure does not overflow.
        if (underlyingPMState.usdValueExposureToUnderlyingAsset >= assetState.usdValueExposureAssetLast) {
            // And: "usdExposureProtocol" does not overflow (unrealistically big).
            protocolState.usdExposureProtocolLast = bound(
                protocolState.usdExposureProtocolLast,
                assetState.usdValueExposureAssetLast,
                type(uint256).max
                    - (underlyingPMState.usdValueExposureToUnderlyingAsset - assetState.usdValueExposureAssetLast)
            );
        }

        // And: State is persisted.
        setDerivedPricingModuleProtocolState(protocolState);
        setDerivedPricingModuleAssetState(assetState);
        setUnderlyingPricingModuleState(assetState.underlyingAsset, underlyingPMState);

        // When: "MainRegistry" calls "processDirectWithdrawal".
        vm.prank(address(mainRegistryExtension_New));
        derivedPricingModule.processDirectWithdrawal(assetState.asset, id, amount);

        // Then: Transaction does not revert.
    }

    // function testFuzz_Success_processDirectWithdrawal(
    //     address asset,
    //     address underlyingAsset,
    //     uint128 exposureAssetLast,
    //     uint128 amount,
    //     uint256 id
    // ) public {
    //     vm.assume(amount > 0);
    //     vm.assume(amount <= exposureAssetLast);

    //     // Set exposure of underlying (primary) asset to max
    //     primaryPricingModule.setExposure(underlyingAsset, exposureAssetLast, type(uint128).max);
    //     // Set usd exposure of protocol to max
    //     derivedPricingModule.setUsdExposureProtocol(type(uint256).max, exposureAssetLast);

    //     address[] memory underlyingAssets = new address[](1);
    //     underlyingAssets[0] = underlyingAsset;
    //     uint128[] memory exposureAssetToUnderlyingAssetsLast = new uint128[](1);
    //     exposureAssetToUnderlyingAssetsLast[0] = exposureAssetLast;

    //     // Add asset to pricing module
    //     derivedPricingModule.addAsset(asset, underlyingAssets);
    //     // Set asset info
    //     derivedPricingModule.setAssetInformation(
    //         asset, exposureAssetLast, exposureAssetLast, exposureAssetToUnderlyingAssetsLast
    //     );

    //     // Set the pricing module for the underlying asset in MainRegistry
    //     mainRegistryExtension_New.setPricingModuleForAsset(underlyingAsset, address(primaryPricingModule));

    //     // Pre check
    //     (, uint128 PreExposureUnderlyingAsset) = primaryPricingModule.exposure(underlyingAsset);
    //     assert(PreExposureUnderlyingAsset == exposureAssetLast);
    //     assert(derivedPricingModule.usdExposureProtocol() == exposureAssetLast);

    //     vm.prank(address(mainRegistryExtension_New));
    //     derivedPricingModule.processDirectWithdrawal(asset, id, amount);

    //     // After check, exposures should have decreased
    //     (, uint128 AfterExposureUnderlyingAsset) = primaryPricingModule.exposure(underlyingAsset);
    //     assert(AfterExposureUnderlyingAsset == exposureAssetLast - amount);
    //     //assert(derivedPricingModule.usdExposureProtocol() == exposureAssetLast - amount);
    // }

    // function testFuzz_Success_processDirectWithdrawal_decreaseInUsdExposureIsGreaterThanLastUsdExposure(
    //     address asset,
    //     address underlyingAsset,
    //     uint128 exposureAssetLast,
    //     uint128 amount,
    //     uint256 id
    // ) public {
    //     vm.assume(amount > 0);
    //     vm.assume(amount >= exposureAssetLast);

    //     // Set exposure of underlying (primary) asset to max
    //     primaryPricingModule.setExposure(underlyingAsset, exposureAssetLast, type(uint128).max);
    //     // Set usd exposure of protocol to max
    //     derivedPricingModule.setUsdExposureProtocol(type(uint256).max, exposureAssetLast);

    //     address[] memory underlyingAssets = new address[](1);
    //     underlyingAssets[0] = underlyingAsset;
    //     uint128[] memory exposureAssetToUnderlyingAssetsLast = new uint128[](1);
    //     exposureAssetToUnderlyingAssetsLast[0] = exposureAssetLast;

    //     // Add asset to pricing module
    //     derivedPricingModule.addAsset(asset, underlyingAssets);
    //     // Set asset info
    //     derivedPricingModule.setAssetInformation(
    //         asset, exposureAssetLast, exposureAssetLast, exposureAssetToUnderlyingAssetsLast
    //     );

    //     // Set the pricing module for the underlying asset in MainRegistry
    //     mainRegistryExtension_New.setPricingModuleForAsset(underlyingAsset, address(primaryPricingModule));

    //     // Pre check
    //     (, uint128 PreExposureUnderlyingAsset) = primaryPricingModule.exposure(underlyingAsset);
    //     assert(PreExposureUnderlyingAsset == exposureAssetLast);
    //     assert(derivedPricingModule.usdExposureProtocol() == exposureAssetLast);

    //     vm.prank(address(mainRegistryExtension_New));
    //     derivedPricingModule.processDirectWithdrawal(asset, id, amount);

    //     // After check, exposures in usd should be zero
    //     (, uint128 AfterExposureUnderlyingAsset) = primaryPricingModule.exposure(underlyingAsset);
    //     assert(AfterExposureUnderlyingAsset == 0);
    //     //assert(derivedPricingModule.usdExposureProtocol() == 0);
    // }
}
