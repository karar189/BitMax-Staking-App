// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title MockUSDC
/// @notice Mock USDC token for Avalanche Fuji testnet deployment
/// @dev Simple ERC20 token with minting functionality for testing
contract MockUSDC is ERC20, Ownable {
    /// @notice Decimals for USDC (6 decimals like real USDC)
    uint8 private constant DECIMALS = 6;

    /// @notice Events
    event TokensMinted(address indexed to, uint256 amount);

    /// @notice Initialize MockUSDC
    constructor() ERC20("Mock USD Coin", "USDC") Ownable(msg.sender) {}

    /// @notice Override decimals to match real USDC
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }

    /// @notice Mint tokens for testing purposes
    /// @param to Address to receive the minted tokens
    /// @param amount Amount of tokens to mint (in wei, considering 6 decimals)
    function mint(address to, uint256 amount) external {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /// @notice Convenience function to mint tokens to caller
    /// @param amount Amount of tokens to mint
    function mintToSelf(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    /// @notice Get token info for verification
    function getTokenInfo() external view returns (string memory, string memory, uint8, uint256) {
        return (name(), symbol(), decimals(), totalSupply());
    }
}