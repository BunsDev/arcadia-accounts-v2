/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { DerivedPricingModule, FixedPointMathLib, IMainRegistry } from "./AbstractDerivedPricingModule.sol";
import { IUniswapV2Pair } from "./interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { PRBMath } from "../libraries/PRBMath.sol";
import { RiskModule } from "../RiskModule.sol";

/**
 * @title Pricing-Module for Uniswap V2 LP tokens
 * @author Pragma Labs
 * @notice The UniswapV2PricingModule stores pricing logic and basic information for Uniswap V2 LP tokens
 * @dev No end-user should directly interact with the UniswapV2PricingModule, only the Main-registry or the contract owner
 * @dev Most logic in this contract is a modifications of
 *      https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2LiquidityMathLibrary.sol#L23
 */
contract UniswapV2PricingModule is DerivedPricingModule {
    using FixedPointMathLib for uint256;
    using PRBMath for uint256;

    /* //////////////////////////////////////////////////////////////
                                CONSTANTS
    ////////////////////////////////////////////////////////////// */

    // The contract address of the Uniswap V2 factory (or an exact clone);
    address internal immutable UNISWAP_V2_FACTORY;

    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Flag indicating if the protocol swap fees are enabled.
    bool public feeOn;

    // The Unique identifiers of the underlying assets of a Liquidity Position.
    mapping(bytes32 assetKey => bytes32[] underlyingAssetKeys) internal assetToUnderlyingAssets;

    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    /**
     * @param mainRegistry_ The address of the Main-registry.
     * @param uniswapV2Factory_ The factory for Uniswap V2 pairs.
     * @dev The ASSET_TYPE, necessary for the deposit and withdraw logic in the Accounts for ERC20 tokens is 0.
     */
    constructor(address mainRegistry_, address uniswapV2Factory_) DerivedPricingModule(mainRegistry_, 0) {
        UNISWAP_V2_FACTORY = uniswapV2Factory_;
    }

    /*///////////////////////////////////////////////////////////////
                        UNISWAP V2 FEE
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Fetches and sets flag if protocol swap fees are enabled.
     */
    function syncFee() external {
        feeOn = IUniswapV2Factory(UNISWAP_V2_FACTORY).feeTo() != address(0);
    }

    /*///////////////////////////////////////////////////////////////
                        ASSET MANAGEMENT
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Adds a new asset (Uniswap V2 pair) to the UniswapV2PricingModule.
     * @param asset The contract address of the Uniswap V2 pair.
     */
    function addAsset(address asset) external {
        address token0 = IUniswapV2Pair(asset).token0();
        address token1 = IUniswapV2Pair(asset).token1();
        require(IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(token0, token1) == asset, "PMUV2_AA: Not a Pool");

        require(IMainRegistry(MAIN_REGISTRY).isAllowed(token0, 0), "PMUV2_AA: Token0 not Allowed");
        require(IMainRegistry(MAIN_REGISTRY).isAllowed(token1, 0), "PMUV2_AA: Token1 not Allowed");

        inPricingModule[asset] = true;

        bytes32[] memory underlyingAssets_ = new bytes32[](2);
        underlyingAssets_[0] = _getKeyFromAsset(token0, 0);
        underlyingAssets_[1] = _getKeyFromAsset(token1, 0);
        assetToUnderlyingAssets[_getKeyFromAsset(asset, 0)] = underlyingAssets_;

        // Will revert in MainRegistry if asset was already added.
        IMainRegistry(MAIN_REGISTRY).addAsset(asset, ASSET_TYPE);
    }

    /*///////////////////////////////////////////////////////////////
                        ASSET INFORMATION
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks for a token address and the corresponding Id if it is allowed.
     * @param asset The contract address of the asset.
     * param assetId The Id of the asset.
     * @return A boolean, indicating if the asset is allowed.
     */
    function isAllowed(address asset, uint256) public view override returns (bool) {
        if (inPricingModule[asset]) return true;

        try IUniswapV2Pair(asset).token0() returns (address token0) {
            address token1 = IUniswapV2Pair(asset).token1();
            return (IUniswapV2Factory(UNISWAP_V2_FACTORY).getPair(token0, token1) == asset)
                && IMainRegistry(MAIN_REGISTRY).isAllowed(token0, 0) && IMainRegistry(MAIN_REGISTRY).isAllowed(token1, 0);
        } catch {
            return false;
        }
    }

    /**
     * @notice Returns the unique identifier of an asset based on the contract address and id.
     * @param asset The contract address of the asset.
     * param assetId The Id of the asset.
     * @return key The unique identifier.
     * @dev The assetId is hard-coded to 0, since both the assets as underlying assets for this Pricing Modules are ERC20's.
     */
    function _getKeyFromAsset(address asset, uint256) internal pure override returns (bytes32 key) {
        assembly {
            key := asset
        }
    }

    /**
     * @notice Returns the contract address and id of an asset based on the unique identifier.
     * @param key The unique identifier.
     * @return asset The contract address of the asset.
     * @return assetId The Id of the asset.
     * @dev The assetId is hard-coded to 0, since both the assets as underlying assets for this Pricing Modules are ERC20's.
     */
    function _getAssetFromKey(bytes32 key) internal pure override returns (address asset, uint256) {
        assembly {
            asset := key
        }

        return (asset, 0);
    }

    /**
     * @notice Returns the unique identifiers of the underlying assets.
     * @param assetKey The unique identifier of the asset.
     * @return underlyingAssetKeys The unique identifiers of the underlying assets.
     */
    function _getUnderlyingAssets(bytes32 assetKey)
        internal
        view
        override
        returns (bytes32[] memory underlyingAssetKeys)
    {
        underlyingAssetKeys = assetToUnderlyingAssets[assetKey];

        if (underlyingAssetKeys.length == 0) {
            // Only used as an off-chain view function by getValue() to return the value of a non deposited Liquidity Position.
            (address asset,) = _getAssetFromKey(assetKey);
            address token0 = IUniswapV2Pair(asset).token0();
            address token1 = IUniswapV2Pair(asset).token1();

            underlyingAssetKeys = new bytes32[](2);
            underlyingAssetKeys[0] = _getKeyFromAsset(token0, 0);
            underlyingAssetKeys[1] = _getKeyFromAsset(token1, 0);
        }
    }

    /**
     * @notice Calculates for a given amount of Asset the corresponding amount(s) of underlying asset(s).
     * @param creditor The contract address of the creditor.
     * @param assetKey The unique identifier of the asset.
     * @param assetAmount The amount of the asset, in the decimal precision of the Asset.
     * param underlyingAssetKeys The unique identifiers of the underlying assets.
     * @return underlyingAssetsAmounts The corresponding amount(s) of Underlying Asset(s), in the decimal precision of the Underlying Asset.
     * @return rateUnderlyingAssetsToUsd The usd rates of 10**18 tokens of underlying asset, with 18 decimals precision.
     */
    function _getUnderlyingAssetsAmounts(
        address creditor,
        bytes32 assetKey,
        uint256 assetAmount,
        bytes32[] memory underlyingAssetKeys
    )
        internal
        view
        override
        returns (
            uint256[] memory underlyingAssetsAmounts,
            RiskModule.AssetValueAndRiskFactors[] memory rateUnderlyingAssetsToUsd
        )
    {
        rateUnderlyingAssetsToUsd = _getRateUnderlyingAssetsToUsd(creditor, underlyingAssetKeys);

        (address asset,) = _getAssetFromKey(assetKey);
        underlyingAssetsAmounts = new uint256[](2);
        (underlyingAssetsAmounts[0], underlyingAssetsAmounts[1]) = _getTrustedTokenAmounts(
            asset, rateUnderlyingAssetsToUsd[0].assetValue, rateUnderlyingAssetsToUsd[1].assetValue, assetAmount
        );

        return (underlyingAssetsAmounts, rateUnderlyingAssetsToUsd);
    }

    /**
     * @notice Returns the trusted amount of token0 provided as liquidity, given two trusted prices of token0 and token1
     * @param pair Address of the Uniswap V2 Liquidity pool
     * @param trustedPriceToken0 Trusted price of an amount of Token0 in a given BaseCurrency
     * @param trustedPriceToken1 Trusted price of an amount of Token1 in a given BaseCurrency
     * @param liquidityAmount The amount of LP tokens (ERC20)
     * @return token0Amount The trusted amount of token0 provided as liquidity
     * @return token1Amount The trusted amount of token1 provided as liquidity
     * @dev Both trusted prices must be for the same BaseCurrency, and for an equal amount of tokens
     *      e.g. if trustedPriceToken0 is the USD price for 10**18 tokens of token0,
     *      than trustedPriceToken2 must be the USD price for 10**18 tokens of token1.
     *      The amount of tokens should be big enough to guarantee enough precision for tokens with small unit-prices
     * @dev The trusted amount of liquidity is calculated by first bringing the liquidity pool in equilibrium,
     *      by calculating what the reserves of the pool would be if a profit-maximizing trade is done.
     *      As such flash-loan attacks are mitigated, where an attacker swaps a large amount of the higher priced token,
     *      to bring the pool out of equilibrium, resulting in liquidity positions with a higher share of the most valuable token.
     * @dev Modification of https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2LiquidityMathLibrary.sol#L23
     */
    function _getTrustedTokenAmounts(
        address pair,
        uint256 trustedPriceToken0,
        uint256 trustedPriceToken1,
        uint256 liquidityAmount
    ) internal view returns (uint256 token0Amount, uint256 token1Amount) {
        uint256 kLast = feeOn ? IUniswapV2Pair(pair).kLast() : 0;
        uint256 totalSupply = IUniswapV2Pair(pair).totalSupply();

        // this also checks that totalSupply > 0
        require(totalSupply > 0, "UV2_GTTA: ZERO_SUPPLY");

        (uint256 reserve0, uint256 reserve1) = _getTrustedReserves(pair, trustedPriceToken0, trustedPriceToken1);

        return _computeTokenAmounts(reserve0, reserve1, totalSupply, liquidityAmount, kLast);
    }

    /**
     * @notice Gets the reserves after an arbitrage moves the price to the profit-maximizing ratio given externally observed trusted price
     * @param pair Address of the Uniswap V2 Liquidity pool
     * @param trustedPriceToken0 Trusted price of an amount of Token0 in a given BaseCurrency
     * @param trustedPriceToken1 Trusted price of an amount of Token1 in a given BaseCurrency
     * @return reserve0 The reserves of token0 in the liquidity pool after arbitrage
     * @return reserve1 The reserves of token1 in the liquidity pool after arbitrage
     * @dev Both trusted prices must be for the same BaseCurrency, and for an equal amount of tokens
     *      e.g. if trustedPriceToken0 is the USD price for 10**18 tokens of token0,
     *      than trustedPriceToken2 must be the USD price for 10**18 tokens of token1.
     *      The amount of tokens should be big enough to guarantee enough precision for tokens with small unit-prices
     * @dev Modification of https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2LiquidityMathLibrary.sol#L23
     */
    function _getTrustedReserves(address pair, uint256 trustedPriceToken0, uint256 trustedPriceToken1)
        internal
        view
        returns (uint256 reserve0, uint256 reserve1)
    {
        // The untrusted reserves from the pair, these can be manipulated!!!
        (reserve0, reserve1,) = IUniswapV2Pair(pair).getReserves();

        require(reserve0 > 0 && reserve1 > 0, "UV2_GTR: ZERO_PAIR_RESERVES");

        // Compute how much to swap to balance the pool with externally observed trusted prices
        (bool token0ToToken1, uint256 amountIn) =
            _computeProfitMaximizingTrade(trustedPriceToken0, trustedPriceToken1, reserve0, reserve1);

        // Pool is balanced -> no need to affect the reserves
        if (amountIn == 0) {
            return (reserve0, reserve1);
        }

        // Pool is unbalanced -> Apply the profit maximalising trade to the reserves
        if (token0ToToken1) {
            uint256 amountOut = _getAmountOut(amountIn, reserve0, reserve1);
            reserve0 += amountIn;
            reserve1 -= amountOut;
        } else {
            uint256 amountOut = _getAmountOut(amountIn, reserve1, reserve0);
            reserve1 += amountIn;
            reserve0 -= amountOut;
        }
    }

    /**
     * @notice Computes the direction and magnitude of the profit-maximizing trade
     * @param trustedPriceToken0 Trusted price of an amount of Token0 in a given BaseCurrency
     * @param trustedPriceToken1 Trusted price of an equal amount of Token1 in a given BaseCurrency
     * @param reserve0 The current untrusted reserves of token0 in the liquidity pool
     * @param reserve1 The current untrusted reserves of token1 in the liquidity pool
     * @return token0ToToken1 The direction of the profit-maximizing trade
     * @return amountIn The amount of tokens to be swapped of the profit-maximizing trade
     * @dev Both trusted prices must be for the same BaseCurrency, and for an equal amount of tokens
     *      e.g. if trustedPriceToken0 is the USD price for 10**18 tokens of token0,
     *      than trustedPriceToken2 must be the USD price for 10**18 tokens of token1.
     *      The amount of tokens should be big enough to guarantee enough precision for tokens with small unit-prices
     * @dev Modification of https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2LiquidityMathLibrary.sol#L23
     * @dev See https://arxiv.org/pdf/1911.03380.pdf for the derivation:
     *      - Maximise: trustedPriceTokenOut * amountOut - trustedPriceTokenIn * amountIn
     *      - Constraints:
     *            * amountIn > 0
     *            * amountOut > 0
     *            * Uniswap V2 AMM: (reserveIn + 997 * amountIn / 1000) * (reserveOut - amountOut) = reserveIn * reserveOut
     *      - Solution:
     *            * amountIn = sqrt[(1000 * reserveIn * amountOut * trustedPriceTokenOut) / (997 * trustedPriceTokenIn)] - 1000 * reserveIn / 997 (if a profit-maximizing trade exists)
     *            * amountIn = 0 (if a profit-maximizing trade does not exists)
     * @dev Function overflows (and reverts) if reserve0 * trustedPriceToken0 > max uint256, however this is not possible in realistic scenario's
     *      This can only happen if trustedPriceToken0 is bigger than 2.23 * 10^43
     *      (for an asset with 0 decimals and reserve0 Max uint112 this would require a unit price of $2.23 * 10^7
     */
    function _computeProfitMaximizingTrade(
        uint256 trustedPriceToken0,
        uint256 trustedPriceToken1,
        uint256 reserve0,
        uint256 reserve1
    ) internal pure returns (bool token0ToToken1, uint256 amountIn) {
        token0ToToken1 = FixedPointMathLib.mulDivDown(reserve0, trustedPriceToken0, reserve1) < trustedPriceToken1;

        uint256 invariant;
        unchecked {
            invariant = reserve0 * reserve1 * 1000; //Can never overflow: uint112 * uint112 * 1000
        }

        uint256 leftSide = FixedPointMathLib.sqrt(
            PRBMath.mulDiv(
                invariant,
                (token0ToToken1 ? trustedPriceToken1 : trustedPriceToken0),
                uint256(token0ToToken1 ? trustedPriceToken0 : trustedPriceToken1) * 997
            )
        );
        uint256 rightSide = (token0ToToken1 ? reserve0 * 1000 : reserve1 * 1000) / 997;

        if (leftSide < rightSide) return (false, 0);

        // compute the amount that must be sent to move the price to the profit-maximizing price
        amountIn = leftSide - rightSide;
    }

    /**
     * @notice Computes the underlying token amounts of a LP-position
     * @param reserve0 The trusted reserves of token0 in the liquidity pool
     * @param reserve1 The trusted reserves of token1 in the liquidity pool
     * @param totalSupply The total supply of LP tokens (ERC20)
     * @param liquidityAmount The amount of LP tokens (ERC20)
     * @param kLast The product of the reserves as of the most recent liquidity event (0 if feeOn is false)
     * @return token0Amount The amount of token0 provided as liquidity
     * @return token1Amount The amount of token1 provided as liquidity
     * @dev Modification of https://github.com/Uniswap/v2-periphery/blob/master/contracts/libraries/UniswapV2LiquidityMathLibrary.sol#L23
     */
    function _computeTokenAmounts(
        uint256 reserve0,
        uint256 reserve1,
        uint256 totalSupply,
        uint256 liquidityAmount,
        uint256 kLast
    ) internal view returns (uint256 token0Amount, uint256 token1Amount) {
        if (feeOn && kLast > 0) {
            uint256 rootK = FixedPointMathLib.sqrt(reserve0 * reserve1);
            uint256 rootKLast = FixedPointMathLib.sqrt(kLast);
            if (rootK > rootKLast) {
                uint256 numerator = totalSupply * (rootK - rootKLast);
                uint256 denominator = rootK * 5 + rootKLast;
                uint256 feeLiquidity = numerator / denominator;
                totalSupply = totalSupply + feeLiquidity;
            }
        }
        token0Amount = FixedPointMathLib.mulDivDown(reserve0, liquidityAmount, totalSupply);
        token1Amount = FixedPointMathLib.mulDivDown(reserve1, liquidityAmount, totalSupply);
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, computes the maximum output amount of the other asset
     * @param reserveIn The reserves of tokenIn in the liquidity pool
     * @param reserveOut The reserves of tokenOut in the liquidity pool
     * @param amountIn The input amount of tokenIn
     * @return amountOut The output amount of tokenIn
     * @dev Derived from Uniswap V2 AMM equation:
     *      (reserveIn + 997 * amountIn / 1000) * (reserveOut - amountOut) = reserveIn * reserveOut
     */
    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}
