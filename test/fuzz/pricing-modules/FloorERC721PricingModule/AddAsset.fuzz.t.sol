/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { FloorERC721PricingModule_Fuzz_Test } from "./_FloorERC721PricingModule.fuzz.t.sol";

import { PricingModule } from "../../../../src/pricing-modules/AbstractPricingModule.sol";

/**
 * @notice Fuzz tests for the function "addAsset" of contract "FloorERC721PricingModule".
 */
contract AddAsset_FloorERC721PricingModule_Fuzz_Test is FloorERC721PricingModule_Fuzz_Test {
    /* ///////////////////////////////////////////////////////////////
                              SETUP
    /////////////////////////////////////////////////////////////// */

    function setUp() public override {
        FloorERC721PricingModule_Fuzz_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                              TESTS
    //////////////////////////////////////////////////////////////*/
    function testFuzz_Revert_addAsset_NonOwner(address unprivilegedAddress_) public {
        // Given: unprivilegedAddress_ is not users.creatorAddress
        vm.assume(unprivilegedAddress_ != users.creatorAddress);
        vm.startPrank(unprivilegedAddress_);
        // When: unprivilegedAddress_ calls addAsset

        // Then: addAsset should revert with "UNAUTHORIZED"
        vm.expectRevert("UNAUTHORIZED");
        floorERC721PricingModule.addAsset(address(mockERC721.nft2), 0, type(uint256).max, oracleNft2ToUsdArr);
        vm.stopPrank();
    }

    function testFuzz_Revert_addAsset_OverwriteExistingAsset() public {
        // Given:
        vm.startPrank(users.creatorAddress);
        // When: users.creatorAddress addAsset twice
        floorERC721PricingModule.addAsset(address(mockERC721.nft2), 0, type(uint256).max, oracleNft2ToUsdArr);
        vm.expectRevert("MR_AA: Asset already in mainreg");
        floorERC721PricingModule.addAsset(address(mockERC721.nft2), 0, type(uint256).max, oracleNft2ToUsdArr);
        vm.stopPrank();
    }

    function testFuzz_Success_addAsset() public {
        // Given: All necessary contracts deployed on setup
        vm.startPrank(users.creatorAddress);
        // When: users.creatorAddress calls addAsset with empty list credit ratings
        floorERC721PricingModule.addAsset(address(mockERC721.nft2), 0, type(uint256).max, oracleNft2ToUsdArr);
        vm.stopPrank();

        // Then: inPricingModule for address(mockERC721.nft2) should return true
        assertTrue(floorERC721PricingModule.inPricingModule(address(mockERC721.nft2)));
        (uint256 idRangeStart, uint256 idRangeEnd, address[] memory oracles) =
            floorERC721PricingModule.getAssetInformation(address(mockERC721.nft2));
        assertEq(idRangeStart, 0);
        assertEq(idRangeEnd, type(uint256).max);
        for (uint256 i; i < oracleNft2ToUsdArr.length; ++i) {
            assertEq(oracles[i], oracleNft2ToUsdArr[i]);
        }
        assertTrue(floorERC721PricingModule.isAllowed(address(mockERC721.nft2), 0));
    }
}
