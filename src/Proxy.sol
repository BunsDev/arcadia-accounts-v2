// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Proxy
 * @author Pragma Labs
 * @dev Implementation based on ERC-1967: Proxy Storage Slots
 * See https://eips.ethereum.org/EIPS/eip-1967
 */
contract Proxy {
    /* //////////////////////////////////////////////////////////////
                                STORAGE
    ////////////////////////////////////////////////////////////// */

    // Storage slot with the address of the current implementation.
    // This is the hardcoded keccak-256 hash of: "eip1967.proxy.implementation" subtracted by 1.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // Storage slot for the Account logic, a struct to avoid storage conflict when dealing with upgradeable contracts.
    struct AddressSlot {
        address value;
    }

    /* //////////////////////////////////////////////////////////////
                                EVENTS
    ////////////////////////////////////////////////////////////// */

    event Upgraded(address indexed implementation);

    /* //////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    ////////////////////////////////////////////////////////////// */

    /**
     * @param logic The contract address of the Account logic.
     */
    constructor(address logic) payable {
        _getAddressSlot(_IMPLEMENTATION_SLOT).value = logic;
        emit Upgraded(logic);
    }

    /**
     * @dev Fallback function that delegates calls to the implementation address.
     * Will run if call data is empty.
     */
    receive() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    /**
     * @dev Fallback function that delegates calls to the implementation address.
     * Will run if no other function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _delegate(_getAddressSlot(_IMPLEMENTATION_SLOT).value);
    }

    /*///////////////////////////////////////////////////////////////
                        IMPLEMENTATION LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns an `AddressSlot` with member `value` located at `slot`.
     * @param slot The slot where the address of the Logic contract is stored.
     * @return r The address stored in slot.
     */
    function _getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /*///////////////////////////////////////////////////////////////
                        DELEGATION LOGIC
    ///////////////////////////////////////////////////////////////*/

    /**
     * @param implementation The contract address of the logic.
     * @dev Delegates the current call to `implementation`.
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
