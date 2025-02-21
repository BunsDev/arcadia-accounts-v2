/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { MainRegistry_Fuzz_Test } from "./_MainRegistry.fuzz.t.sol";

import { RiskConstants } from "../../../src/libraries/RiskConstants.sol";

/**
 * @notice Fuzz tests for the function "setRiskParametersOfDerivedPricingModule" of contract "MainRegistry".
 */
contract SetRiskParametersOfDerivedPricingModule_MainRegistry_Fuzz_Test is MainRegistry_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        MainRegistry_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_setRiskParametersOfDerivedPricingModule_NonRiskManager(
        address unprivilegedAddress_,
        uint128 maxUsdExposureProtocol,
        uint16 riskFactor
    ) public {
        vm.assume(unprivilegedAddress_ != users.riskManager);

        vm.startPrank(unprivilegedAddress_);
        vm.expectRevert("MR_SRPDPM: Not Authorized");
        mainRegistryExtension.setRiskParametersOfDerivedPricingModule(
            address(creditorUsd), address(derivedPricingModule), maxUsdExposureProtocol, riskFactor
        );
        vm.stopPrank();
    }

    function testFuzz_Success_setRiskParametersOfDerivedPricingModule(uint128 maxUsdExposureProtocol, uint16 riskFactor)
        public
    {
        riskFactor = uint16(bound(riskFactor, 0, RiskConstants.RISK_FACTOR_UNIT));

        vm.prank(users.riskManager);
        mainRegistryExtension.setRiskParametersOfDerivedPricingModule(
            address(creditorUsd), address(derivedPricingModule), maxUsdExposureProtocol, riskFactor
        );

        (, uint128 actualMaxUsdExposureProtocol, uint16 actualRiskFactor) =
            derivedPricingModule.riskParams(address(creditorUsd));
        assertEq(actualMaxUsdExposureProtocol, maxUsdExposureProtocol);
        assertEq(actualRiskFactor, riskFactor);
    }
}
