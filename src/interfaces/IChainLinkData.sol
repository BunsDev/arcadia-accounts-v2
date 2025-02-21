// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// @notice Interface for ChainLink Data Feed, it is based on https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
interface IChainLinkData {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    // @notice Returns the aggregator, added by arcadia.
    function aggregator() external view returns (address);

    // @notice Returns the minimum answer, added by arcadia.
    function minAnswer() external view returns (int192);

    // @notice Returns the minimum answer, added by arcadia.
    function maxAnswer() external view returns (int192);
}
