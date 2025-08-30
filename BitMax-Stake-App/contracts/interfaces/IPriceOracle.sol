// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IPriceOracle
/// @notice Interface for price oracle contracts that provide price feeds
interface IPriceOracle {
    /// @notice Get the latest price for a given token
    /// @param token The token address to get price for
    /// @return price The latest price in USD (8 decimals)
    /// @return timestamp The timestamp when the price was last updated
    function getLatestPrice(address token) external view returns (uint256 price, uint256 timestamp);
    
    /// @notice Check if a price is within acceptable thresholds
    /// @param token The token address to check
    /// @param threshold The threshold percentage in basis points (e.g., 5000 = 50%)
    /// @return isWithinThreshold Whether the price is within the threshold
    function isPriceWithinThreshold(address token, uint256 threshold) external view returns (bool isWithinThreshold);
    
    /// @notice Get the price change percentage over a time period
    /// @param token The token address to check
    /// @param timePeriod The time period in seconds
    /// @return priceChange The price change percentage in basis points
    function getPriceChange(address token, uint256 timePeriod) external view returns (int256 priceChange);
    
    /// @notice Check if the oracle is healthy and providing valid data
    /// @return isHealthy Whether the oracle is healthy
    function isHealthy() external view returns (bool isHealthy);
    
    /// @notice Check if threshold has been reached for a token
    /// @param token The token address to check
    /// @return Whether threshold has been reached
    function thresholdReached(address token) external view returns (bool);
    
    /// @notice Get the heartbeat timeout for price updates
    /// @return heartbeat The heartbeat timeout in seconds
    function getHeartbeat() external view returns (uint256 heartbeat);
} 