/**
 * Created by Pragma Labs
 * SPDX-License-Identifier: BUSL-1.1
 */
pragma solidity 0.8.19;

import { ActionBase, ActionData } from "./ActionBase.sol";
import { IERC20 } from "../interfaces/IERC20.sol";
import { IERC1155 } from "../interfaces/IERC1155.sol";
import { IPermit2 } from "../interfaces/IPermit2.sol";

/**
 * @title Generic multicall action
 * @author Pragma Labs
 * @notice Calls any external contract with arbitrary data.
 * @dev Only calls are used, no delegatecalls.
 * @dev This address will approve random addresses. Do not store any funds on this address!
 */
contract ActionMultiCall is ActionBase {
    /* //////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    constructor() { }

    /* //////////////////////////////////////////////////////////////
                            ACTION LOGIC
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Calls a series of addresses with arbitrary calldata.
     * @param actionData A bytes object containing three actionAssetData structs, a TokenPermissions struct, an address array and a bytes array.
     * @return resultData An actionAssetData struct with the balances of this ActionMultiCall address.
     * @dev input address is not used in this generic action.
     */
    function executeAction(bytes calldata actionData) external override returns (ActionData memory) {
        (,,, ActionData memory depositData, address[] memory to, bytes[] memory data) = abi.decode(
            actionData, (ActionData, ActionData, IPermit2.PermitBatchTransferFrom, ActionData, address[], bytes[])
        );

        uint256 callLength = to.length;

        require(data.length == callLength, "EA: Length mismatch");

        for (uint256 i; i < callLength;) {
            (bool success, bytes memory result) = to[i].call(data[i]);
            require(success, string(result));

            unchecked {
                ++i;
            }
        }

        for (uint256 i; i < depositData.assets.length;) {
            if (depositData.assetTypes[i] == 0) {
                depositData.assetAmounts[i] = IERC20(depositData.assets[i]).balanceOf(address(this));
            } else if (depositData.assetTypes[i] == 1) {
                depositData.assetAmounts[i] = 1;
            } else if (depositData.assetTypes[i] == 2) {
                depositData.assetAmounts[i] =
                    IERC1155(depositData.assets[i]).balanceOf(address(this), depositData.assetIds[i]);
            }
            unchecked {
                ++i;
            }
        }

        return depositData;
    }

    /* //////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    ////////////////////////////////////////////////////////////// */

    /**
     * @notice Repays an exact amount to a creditor.
     * @param creditor The contract address of the creditor.
     * @param asset The contract address of the asset that is being repaid.
     * @param account The contract address of the Account for which the debt is being repaid.
     * @param amount The amount of debt to.
     * @dev Can be called as one of the calls in executeAction, but fetches the actual contract balance after other DeFi interactions.
     */
    function executeRepay(address creditor, address asset, address account, uint256 amount) external {
        if (amount < 1) {
            amount = IERC20(asset).balanceOf(address(this));
        }

        (bool success, bytes memory data) =
            creditor.call(abi.encodeWithSignature("repay(uint256,address)", amount, account));
        require(success, string(data));
    }
}
