/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { Constants, StandardERC4626PricingModule_Fuzz_Test } from "./_StandardERC4626PricingModule.fuzz.t.sol";

import { ERC4626DifferentDecimals } from "../../.././utils/mocks/ERC4626DifferentDecimals.sol";
import { PricingModule_New } from "../../../../src/pricing-modules/AbstractPricingModule_New.sol";
import { StandardERC4626PricingModule } from "../../../../src/pricing-modules/StandardERC4626PricingModule.sol";

/**
 * @notice Fuzz tests for the "addAsset" of contract "StandardERC4626PricingModule".
 */
contract AddAsset_StandardERC4626PricingModule_Fuzz_Test is StandardERC4626PricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        StandardERC4626PricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_addAsset_NonOwner(address unprivilegedAddress_, address asset) public {
        vm.assume(unprivilegedAddress_ != users.creatorAddress);
        vm.startPrank(unprivilegedAddress_);
        vm.expectRevert("UNAUTHORIZED");
        erc4626PricingModule.addAsset(asset, emptyRiskVarInput_New);
        vm.stopPrank();
    }

    function testFuzz_Revert_addAsset_DecimalsDontMatch(uint8 decimals) public {
        vm.assume(decimals != mockERC20.token1.decimals());
        vm.assume(decimals <= 20);
        vm.prank(users.tokenCreatorAddress);
        ERC4626DifferentDecimals ybToken = new ERC4626DifferentDecimals(decimals, mockERC20.token1);

        vm.startPrank(users.creatorAddress);
        vm.expectRevert("PM4626_AA: Decimals don't match");
        erc4626PricingModule.addAsset(address(ybToken), emptyRiskVarInput_New);
        vm.stopPrank();
    }

    function testFuzz_Revert_addAsset_OverwriteExistingAsset() public {
        vm.startPrank(users.creatorAddress);
        erc4626PricingModule.addAsset(address(ybToken1), emptyRiskVarInput_New);
        vm.expectRevert("PM4626_AA: already added");
        erc4626PricingModule.addAsset(address(ybToken1), emptyRiskVarInput_New);
        vm.stopPrank();

        assertTrue(erc4626PricingModule.inPricingModule(address(ybToken1)));
    }

    function testFuzz_Success_addAsset_EmptyListRiskVariables() public {
        vm.startPrank(users.creatorAddress);
        erc4626PricingModule.addAsset(address(ybToken1), emptyRiskVarInput_New);
        vm.stopPrank();

        assertTrue(erc4626PricingModule.inPricingModule(address(ybToken1)));
        assertEq(erc4626PricingModule.assetsInPricingModule(0), address(ybToken1));

        (uint64 assetUnit) = erc4626PricingModule.erc4626AssetToInformation(address(ybToken1));
        assertEq(assetUnit, 10 ** mockERC20.token1.decimals());

        (
            uint128 exposureAssetLast,
            uint128 usdValueExposureAssetLast,
            address[] memory underlyingAssets,
            uint128[] memory exposureAssetToUnderlyingAssetsLast
        ) = erc4626PricingModule.getAssetInformation(address(ybToken1));

        assertEq(exposureAssetLast, 0);
        assertEq(usdValueExposureAssetLast, 0);
        assertEq(underlyingAssets[0], address(mockERC20.token1));
        assertEq(exposureAssetToUnderlyingAssetsLast[0], 0);

        assertTrue(erc4626PricingModule.isAllowListed(address(ybToken1), 0));
        // We ensure that the correct oracle from the underlying asset was added in
        // ERC4626AssetInformation through our testing of GetValue().
    }

    function testFuzz_Success_addAsset_NonFullListRiskVariables() public {
        vm.startPrank(users.creatorAddress);
        PricingModule_New.RiskVarInput[] memory riskVars_ = new PricingModule_New.RiskVarInput[](1);
        riskVars_[0] = PricingModule_New.RiskVarInput({
            baseCurrency: 0,
            asset: address(0),
            collateralFactor: collateralFactor,
            liquidationFactor: liquidationFactor
        });

        erc4626PricingModule.addAsset(address(ybToken1), riskVars_);
        vm.stopPrank();

        assertTrue(erc4626PricingModule.inPricingModule(address(ybToken1)));
    }
}
