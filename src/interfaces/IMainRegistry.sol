/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: MIT
 */
pragma solidity 0.8.19;

import { IPricingModule } from "./IPricingModule.sol";

interface IMainRegistry {
    /**
     * @notice Adds a new asset to the Main Registry.
     * @param asset The contract address of the asset.
     * @param assetType Identifier for the type of the asset:
     * 0 = ERC20.
     * 1 = ERC721.
     * 2 = ERC1155.
     */
    function addAsset(address asset, uint256 assetType) external;

    /**
     * @notice Returns the number of baseCurrencies.
     * @return Counter for the number of baseCurrencies in use.
     */
    function baseCurrencyCounter() external view returns (uint256);

    /**
     * @notice Returns the Factory address.
     * @return factory The contract address of the Factory.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the contract address of a baseCurrency.
     * @param index The index of the baseCurrency in the array baseCurrencies.
     * @return baseCurrency The contract address of a baseCurrency.
     */
    function baseCurrencies(uint256 index) external view returns (address);

    /**
     * @notice Checks if a contract is a baseCurrency.
     * @param baseCurrency The contract address of the baseCurrency.
     * @return boolean.
     */
    function isBaseCurrency(address baseCurrency) external view returns (bool);

    /**
     * @notice Checks if an action is allowed.
     * @param action The contract address of the action.
     * @return boolean.
     */
    function isActionAllowed(address action) external view returns (bool);

    /**
     * @notice Batch deposit multiple assets.
     * @param assetAddresses Array of the contract addresses of the assets.
     * @param assetIds Array of the IDs of the assets.
     * @param amounts Array with the amounts of the assets.
     * @return assetTypes Array with the types of the assets.
     * 0 = ERC20.
     * 1 = ERC721.
     * 2 = ERC1155.
     */
    function batchProcessDeposit(
        address creditor,
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata amounts
    ) external returns (uint256[] memory);

    /**
     * @notice Batch withdraw multiple assets.
     * @param assetAddresses Array of the contract addresses of the assets.
     * @param assetIds Array of the IDs of the assets.
     * @param amounts Array with the amounts of the assets.
     * @return assetTypes Array with the types of the assets.
     * 0 = ERC20.
     * 1 = ERC721.
     * 2 = ERC1155.
     */
    function batchProcessWithdrawal(
        address creditor,
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata amounts
    ) external returns (uint256[] memory);

    /**
     * @notice Calculates the combined value of a combination of assets, denominated in a given BaseCurrency.
     * @param baseCurrency The contract address of the BaseCurrency.
     * @param creditor The contract address of the creditor.
     * @param assetAddresses Array of the contract addresses of the assets.
     * @param assetIds Array of the IDs of the assets.
     * @param assetAmounts Array with the amounts of the assets.
     * @return valueInBaseCurrency The combined value of the assets, denominated in BaseCurrency.
     */
    function getTotalValue(
        address baseCurrency,
        address creditor,
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts
    ) external view returns (uint256);

    /**
     * @notice Calculates the collateralValue of a combination of assets, denominated in a given BaseCurrency.
     * @param baseCurrency The contract address of the BaseCurrency.
     * @param creditor The contract address of the creditor.
     * @param assetAddresses Array of the contract addresses of the assets.
     * @param assetIds Array of the IDs of the assets.
     * @param assetAmounts Array with the amounts of the assets.
     * @return collateralValue The collateral value of the assets, denominated in BaseCurrency.
     */
    function getCollateralValue(
        address baseCurrency,
        address creditor,
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts
    ) external view returns (uint256);

    /**
     * @notice Calculates the getLiquidationValue of a combination of assets, denominated in a given BaseCurrency.
     * @param baseCurrency The contract address of the BaseCurrency.
     * @param creditor The contract address of the creditor.
     * @param assetAddresses Array of the contract addresses of the assets.
     * @param assetIds Array of the IDs of the assets.
     * @param assetAmounts Array with the amounts of the assets.
     * @return liquidationValue The liquidation value of the assets, denominated in BaseCurrency.
     */
    function getLiquidationValue(
        address baseCurrency,
        address creditor,
        address[] calldata assetAddresses,
        uint256[] calldata assetIds,
        uint256[] calldata assetAmounts
    ) external view returns (uint256);

    function getUsdValue(IPricingModule.GetValueInput memory getValueInput) external view returns (uint256);
}
