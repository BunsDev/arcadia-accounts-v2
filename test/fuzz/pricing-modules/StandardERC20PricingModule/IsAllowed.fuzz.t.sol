/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { StandardERC20PricingModule_Fuzz_Test } from "./_StandardERC20PricingModule.fuzz.t.sol";

/**
 * @notice Fuzz tests for the function "isAllowed" of contract "StandardERC20PricingModule".
 */
contract IsAllowed_StandardERC20PricingModule_Fuzz_Test is StandardERC20PricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        StandardERC20PricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Success_isAllowed_Positive(uint256 assetId) public {
        assertTrue(erc20PricingModule.isAllowed(address(mockERC20.stable1), assetId));
    }

    function testFuzz_Success_isAllowed_Negative(address randomAsset, uint256 assetId) public {
        vm.assume(randomAsset != address(mockERC20.stable1));
        vm.assume(randomAsset != address(mockERC20.stable2));
        vm.assume(randomAsset != address(mockERC20.token1));
        vm.assume(randomAsset != address(mockERC20.token2));

        assertFalse(erc20PricingModule.isAllowed(randomAsset, assetId));
    }
}
