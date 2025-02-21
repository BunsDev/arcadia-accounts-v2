/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { StandardERC20PricingModule_Fuzz_Test } from "./_StandardERC20PricingModule.fuzz.t.sol";

import { Constants } from "../../../utils/Constants.sol";

/**
 * @notice Fuzz tests for the function "getValue" of contract "StandardERC20PricingModule".
 */
contract GetValue_StandardERC20PricingModule_Fuzz_Test is StandardERC20PricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        StandardERC20PricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_getValue_Overflow(uint256 rateToken1ToUsdNew, uint256 amountToken1) public {
        // No Overflow OracleHub
        vm.assume(rateToken1ToUsdNew <= type(uint256).max / Constants.WAD);
        vm.assume(rateToken1ToUsdNew > 0);

        vm.assume(
            amountToken1
                > type(uint256).max / (Constants.WAD * rateToken1ToUsdNew / 10 ** Constants.tokenOracleDecimals)
        );

        vm.prank(users.defaultTransmitter);
        mockOracles.token1ToUsd.transmit(int256(rateToken1ToUsdNew));

        // When: getValue called
        // Then: getValue should be reverted
        vm.expectRevert(bytes(""));
        erc20PricingModule.getValue(address(creditorUsd), address(mockERC20.token1), 0, amountToken1);
    }

    function testFuzz_Success_getValue(uint256 rateToken1ToUsdNew, uint256 amountToken1) public {
        // No Overflow OracleHub
        vm.assume(rateToken1ToUsdNew <= type(uint256).max / Constants.WAD);

        if (rateToken1ToUsdNew != 0) {
            vm.assume(
                amountToken1
                    <= type(uint256).max / (Constants.WAD * rateToken1ToUsdNew / 10 ** Constants.tokenOracleDecimals)
            );
        }

        vm.prank(users.defaultTransmitter);
        mockOracles.token1ToUsd.transmit(int256(rateToken1ToUsdNew));

        uint256 expectedValueInUsd = (Constants.WAD * rateToken1ToUsdNew / 10 ** Constants.tokenOracleDecimals)
            * amountToken1 / 10 ** Constants.tokenDecimals;

        // When: getValue called
        (uint256 actualValueInUsd,,) =
            erc20PricingModule.getValue(address(creditorUsd), address(mockERC20.token1), 0, amountToken1);

        // Then: actualValueInUsd should be equal to expectedValueInUsd
        assertEq(actualValueInUsd, expectedValueInUsd);
    }
}
