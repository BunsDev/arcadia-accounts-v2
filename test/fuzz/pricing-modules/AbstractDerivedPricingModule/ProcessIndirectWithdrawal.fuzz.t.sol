/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { AbstractDerivedPricingModule_Fuzz_Test } from "./_AbstractDerivedPricingModule.fuzz.t.sol";

/**
 * @notice Fuzz tests for the function "processIndirectWithdrawal" of contract "AbstractDerivedPricingModule".
 */
contract ProcessIndirectWithdrawal_AbstractDerivedPricingModule_Fuzz_Test is AbstractDerivedPricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        AbstractDerivedPricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_processIndirectWithdrawal_NonMainRegistry(
        address unprivilegedAddress_,
        address creditor,
        address asset,
        uint256 id,
        uint256 exposureUpperAssetToAsset,
        int256 deltaExposureUpperAssetToAsset
    ) public {
        vm.assume(unprivilegedAddress_ != address(mainRegistryExtension));

        vm.startPrank(unprivilegedAddress_);
        vm.expectRevert("APM: ONLY_MAIN_REGISTRY");
        derivedPricingModule.processIndirectWithdrawal(
            creditor, asset, id, exposureUpperAssetToAsset, deltaExposureUpperAssetToAsset
        );
        vm.stopPrank();
    }

    function testFuzz_Success_processIndirectWithdrawal_ZeroExposureAsset(
        DerivedPricingModuleProtocolState memory protocolState,
        DerivedPricingModuleAssetState memory assetState,
        UnderlyingPricingModuleState memory underlyingPMState,
        uint256 exposureUpperAssetToAsset,
        uint256 deltaExposureUpperAssetToAsset
    ) public {
        // Given: Underflow on exposureAsset (test-case).
        deltaExposureUpperAssetToAsset =
            bound(deltaExposureUpperAssetToAsset, assetState.exposureAssetLast, uint256(type(int256).max));
        int256 deltaExposureUpperAssetToAsset_ = -int256(deltaExposureUpperAssetToAsset);

        // And: Withdrawal does not revert.
        (protocolState, assetState, underlyingPMState, exposureUpperAssetToAsset, deltaExposureUpperAssetToAsset_) =
        givenNonRevertingWithdrawal(
            protocolState, assetState, underlyingPMState, exposureUpperAssetToAsset, deltaExposureUpperAssetToAsset_
        );

        // And: State is persisted.
        setDerivedPricingModuleProtocolState(protocolState, assetState.creditor);
        setDerivedPricingModuleAssetState(assetState);
        setUnderlyingPricingModuleState(assetState, underlyingPMState);

        // When: "MainRegistry" calls "processIndirectWithdrawal".
        vm.prank(address(mainRegistryExtension));
        (bool PRIMARY_FLAG, uint256 usdExposureUpperAssetToAsset) = derivedPricingModule.processIndirectWithdrawal(
            assetState.creditor,
            assetState.asset,
            assetState.assetId,
            exposureUpperAssetToAsset,
            deltaExposureUpperAssetToAsset_
        );

        // Then: PRIMARY_FLAG is false.
        assertFalse(PRIMARY_FLAG);

        // And:
        assertEq(usdExposureUpperAssetToAsset, 0);
    }

    function testFuzz_Success_processIndirectWithdrawal_ZeroUsdValueExposureAsset(
        DerivedPricingModuleProtocolState memory protocolState,
        DerivedPricingModuleAssetState memory assetState,
        UnderlyingPricingModuleState memory underlyingPMState,
        uint256 exposureUpperAssetToAsset,
        int256 deltaExposureUpperAssetToAsset
    ) public {
        // Given: "usdExposureAsset" is 0 (test-case).
        underlyingPMState.usdValue = 0;

        // And: Withdrawal does not revert.
        (protocolState, assetState, underlyingPMState, exposureUpperAssetToAsset, deltaExposureUpperAssetToAsset) =
        givenNonRevertingWithdrawal(
            protocolState, assetState, underlyingPMState, exposureUpperAssetToAsset, deltaExposureUpperAssetToAsset
        );

        // And: State is persisted.
        setDerivedPricingModuleProtocolState(protocolState, assetState.creditor);
        setDerivedPricingModuleAssetState(assetState);
        setUnderlyingPricingModuleState(assetState, underlyingPMState);

        // When: "MainRegistry" calls "processIndirectWithdrawal".
        vm.prank(address(mainRegistryExtension));
        (bool PRIMARY_FLAG, uint256 usdExposureUpperAssetToAsset) = derivedPricingModule.processIndirectWithdrawal(
            assetState.creditor,
            assetState.asset,
            assetState.assetId,
            exposureUpperAssetToAsset,
            deltaExposureUpperAssetToAsset
        );

        // Then: PRIMARY_FLAG is false.
        assertFalse(PRIMARY_FLAG);

        // And:
        assertEq(usdExposureUpperAssetToAsset, 0);
    }

    function testFuzz_Success_processIndirectWithdrawal_NonZeroValues(
        DerivedPricingModuleProtocolState memory protocolState,
        DerivedPricingModuleAssetState memory assetState,
        UnderlyingPricingModuleState memory underlyingPMState,
        uint256 exposureUpperAssetToAsset,
        int256 deltaExposureUpperAssetToAsset
    ) public {
        // Given: "usdExposureToUnderlyingAsset" is not zero (test-case).
        underlyingPMState.usdValue = bound(underlyingPMState.usdValue, 1, type(uint128).max);

        // And: Withdrawal does not revert.
        (protocolState, assetState, underlyingPMState, exposureUpperAssetToAsset, deltaExposureUpperAssetToAsset) =
        givenNonRevertingWithdrawal(
            protocolState, assetState, underlyingPMState, exposureUpperAssetToAsset, deltaExposureUpperAssetToAsset
        );

        // And: exposureAsset is not zero (test-case).
        uint256 exposureAsset;
        if (deltaExposureUpperAssetToAsset > 0) {
            exposureAsset = assetState.exposureAssetLast + uint256(deltaExposureUpperAssetToAsset);
            vm.assume(exposureAsset != 0);
        } else {
            vm.assume(uint256(-deltaExposureUpperAssetToAsset) < assetState.exposureAssetLast);
            exposureAsset = uint256(assetState.exposureAssetLast) - uint256(-deltaExposureUpperAssetToAsset);
        }

        // And: State is persisted.
        setDerivedPricingModuleProtocolState(protocolState, assetState.creditor);
        setDerivedPricingModuleAssetState(assetState);
        setUnderlyingPricingModuleState(assetState, underlyingPMState);

        // When: "MainRegistry" calls "processIndirectWithdrawal".
        vm.prank(address(mainRegistryExtension));
        (bool PRIMARY_FLAG, uint256 usdExposureUpperAssetToAsset) = derivedPricingModule.processIndirectWithdrawal(
            assetState.creditor,
            assetState.asset,
            assetState.assetId,
            exposureUpperAssetToAsset,
            deltaExposureUpperAssetToAsset
        );

        // Then: PRIMARY_FLAG is false.
        assertFalse(PRIMARY_FLAG);

        // And: Correct "usdExposureUpperAssetToAsset" is returned.
        uint256 usdExposureUpperAssetToAssetExpected =
            underlyingPMState.usdValue * exposureUpperAssetToAsset / exposureAsset;
        assertEq(usdExposureUpperAssetToAsset, usdExposureUpperAssetToAssetExpected);
    }
}
