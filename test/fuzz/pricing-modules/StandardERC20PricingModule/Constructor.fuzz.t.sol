/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { StandardERC20PricingModule_Fuzz_Test } from "./_StandardERC20PricingModule.fuzz.t.sol";

import { StandardERC20PricingModuleExtension } from "../../../utils/Extensions.sol";

/**
 * @notice Fuzz tests for the function "constructor" of contract "StandardERC20PricingModule".
 */
contract Constructor_StandardERC20PricingModule_Fuzz_Test is StandardERC20PricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        StandardERC20PricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Success_deployment(address mainRegistry_, address oracleHub_) public {
        vm.startPrank(users.creatorAddress);
        StandardERC20PricingModuleExtension erc20PricingModule_ = new StandardERC20PricingModuleExtension(
            mainRegistry_,
            oracleHub_);
        vm.stopPrank();

        assertEq(erc20PricingModule_.MAIN_REGISTRY(), mainRegistry_);
        assertEq(erc20PricingModule_.ORACLE_HUB(), oracleHub_);
        assertEq(erc20PricingModule_.ASSET_TYPE(), 0);
        assertTrue(erc20PricingModule_.getPrimaryFlag());
    }
}
