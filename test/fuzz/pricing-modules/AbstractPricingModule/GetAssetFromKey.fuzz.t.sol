/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { AbstractPricingModule_Fuzz_Test } from "./_AbstractPricingModule.fuzz.t.sol";

/**
 * @notice Fuzz tests for the function "_getAssetFromKey" of contract "AbstractPricingModule".
 */
contract GetAssetFromKey_AbstractPricingModule_Fuzz_Test is AbstractPricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        AbstractPricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Success_getAssetFromKey(address asset, uint96 assetId) public {
        bytes32 key = bytes32(abi.encodePacked(assetId, asset));
        (address actualAsset, uint256 actualAssetId) = pricingModule.getAssetFromKey(key);

        assertEq(actualAsset, asset);
        assertEq(actualAssetId, assetId);
    }
}
