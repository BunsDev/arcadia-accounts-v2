// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { ERC1155 } from "../../../lib/solmate/src/tokens/ERC1155.sol";
import { Strings } from "../../../src/libraries/Strings.sol";

contract ERC1155Mock is ERC1155 {
    using Strings for uint256;

    string baseURI;
    address owner;
    mapping(uint256 => string) _uri;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    string public name;

    string public symbol;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 id, uint256 amount) public {
        _mint(to, id, amount, "");
    }

    function _setUri(uint256 id, string memory newUri) internal virtual {
        _uri[id] = newUri;
    }

    /**
     * @dev Function to set the URI for all NFT IDs
     */
    function setUri(uint256 id, string calldata newUri) external onlyOwner {
        _setUri(id, newUri);
    }

    function setBaseUri(string calldata newBaseUri) external onlyOwner {
        baseURI = newBaseUri;
    }

    /**
     * @dev Returns the URI of a token given its ID
     * @param id ID of the token to query
     * @return uri of the token or an empty string if it does not exist
     */
    function uri(uint256 id) public view override returns (string memory) {
        return bytes(_uri[id]).length > 0 ? _uri[id] : string(abi.encodePacked(baseURI, id.toString()));
    }
}
