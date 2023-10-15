// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DateToBlock {
    uint256 constant GENESIS_BLOCK_TIME = 1438269988; // Ethereum Genesis block time
    uint256 constant AVG_BLOCK_TIME = 15; // Approximate block time in seconds

    // Convert date in YYMMDD format to approximate block number
    function dateToBlockNumber(string memory dateYYMMDD) public pure returns (uint256) {
        uint256 epochTime = parseDateToEpoch(dateYYMMDD);
        return (epochTime - GENESIS_BLOCK_TIME) / AVG_BLOCK_TIME;
    }

    // Convert block number to date in YYMMDD format
    function blockNumberToDate(uint256 blockNumber) public view returns (string memory) {
        uint256 blockTime = getBlockTime(blockNumber);
        return formatEpochToDate(blockTime);
    }

    // Convert date in YYMMDD format to epoch time (simplified)
    function parseDateToEpoch(string memory date) internal pure returns (uint256) {
        // Assume date format is YYMMDD and each component is two digits
        bytes memory dateBytes = bytes(date);
        uint256 year = uint256(uint8(dateBytes[0]) - 48) * 10 + uint256(uint8(dateBytes[1]) - 48);
        uint256 month = uint256(uint8(dateBytes[2]) - 48) * 10 + uint256(uint8(dateBytes[3]) - 48);
        uint256 day = uint256(uint8(dateBytes[4]) - 48) * 10 + uint256(uint8(dateBytes[5]) - 48);

        // Simplified conversion, for demonstration only
        return ((year * 365 + month * 30 + day) * 24 * 60 * 60);
    }

    // Get block time using block number (placeholder, for demonstration only)
    function getBlockTime(uint256 blockNumber) internal view returns (uint256) {
        // This is a placeholder. In a real implementation, you may fetch the actual block time
        return block.timestamp - (block.number - blockNumber) * AVG_BLOCK_TIME;
    }

    // Convert epoch time to date in YYMMDD format (simplified)
    function formatEpochToDate(uint256 epochTime) internal pure returns (string memory) {
        uint256 day = (epochTime / (24 * 60 * 60)) % 30;
        uint256 month = (epochTime / (24 * 60 * 60 * 30)) % 12;
        uint256 year = (epochTime / (24 * 60 * 60 * 365));

        // Concatenate as string in YYMMDD format
        return string(abi.encodePacked(toString(year), toString(month), toString(day)));
    }

    // Convert uint256 to string (helper function)
    function toString(uint256 value) internal pure returns(string memory) {
        if (value == 0) {
            return "00";
        }
        uint256 tempValue = value;
        uint256 digits;
        while (tempValue != 0) {
            digits++;
            tempValue /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
