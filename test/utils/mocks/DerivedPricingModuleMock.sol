// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { AbstractDerivedPricingModuleExtension } from "../Extensions.sol";
import { RiskModule } from "../../../src/RiskModule.sol";

contract DerivedPricingModuleMock is AbstractDerivedPricingModuleExtension {
    mapping(bytes32 assetKey => bytes32[] underlyingAssetKeys) internal assetToUnderlyingAssets;

    uint256 internal underlyingAssetAmount;
    bool internal returnRateUnderlyingAssetToUsd;
    uint256 internal rateUnderlyingAssetToUsd;

    constructor(address mainRegistry_, uint256 assetType_)
        AbstractDerivedPricingModuleExtension(mainRegistry_, assetType_)
    { }

    function isAllowed(address asset, uint256) public view override returns (bool) { }

    function setUnderlyingAssetsAmount(uint256 underlyingAssetAmount_) public {
        underlyingAssetAmount = underlyingAssetAmount_;
    }

    function setRateUnderlyingAssetToUsd(uint256 rateUnderlyingAssetToUsd_) public {
        rateUnderlyingAssetToUsd = rateUnderlyingAssetToUsd_;
        returnRateUnderlyingAssetToUsd = true;
    }

    function addAsset(
        address asset,
        uint256 assetId,
        address[] memory underlyingAssets_,
        uint256[] memory underlyingAssetIds
    ) public {
        require(!inPricingModule[asset], "ADPME_AA: already added");
        inPricingModule[asset] = true;

        bytes32 assetKey = _getKeyFromAsset(asset, assetId);
        bytes32[] memory underlyingAssetKeys = new bytes32[](underlyingAssets_.length);
        for (uint256 i; i < underlyingAssets_.length;) {
            underlyingAssetKeys[i] = _getKeyFromAsset(underlyingAssets_[i], underlyingAssetIds[i]);
            ++i;
        }
        assetToUnderlyingAssets[assetKey] = underlyingAssetKeys;
    }

    function _getUnderlyingAssetsAmounts(address, bytes32, uint256, bytes32[] memory)
        internal
        view
        override
        returns (
            uint256[] memory underlyingAssetsAmount,
            RiskModule.AssetValueAndRiskFactors[] memory rateUnderlyingAssetsToUsd
        )
    {
        underlyingAssetsAmount = new uint256[](1);
        underlyingAssetsAmount[0] = underlyingAssetAmount;

        // If rateUnderlyingAssetToUsd is set, also return rateUnderlyingAssetsToUsd.
        if (returnRateUnderlyingAssetToUsd) {
            rateUnderlyingAssetsToUsd = new RiskModule.AssetValueAndRiskFactors[](1);
            rateUnderlyingAssetsToUsd[0].assetValue = rateUnderlyingAssetToUsd;
        }

        return (underlyingAssetsAmount, rateUnderlyingAssetsToUsd);
    }

    function _getUnderlyingAssets(bytes32 assetKey)
        internal
        view
        override
        returns (bytes32[] memory underlyingAssets)
    {
        underlyingAssets = assetToUnderlyingAssets[assetKey];
    }
}
