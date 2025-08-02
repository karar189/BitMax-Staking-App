// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title ConfigurableERC20
/// @notice Generic ERC20 + ERC20Permit token with optional mint limit
/// @dev Deploy once per asset (e.g., Reward, Staking) by passing different constructor params
contract ConfigurableERC20 is ERC20, ERC20Permit, Ownable {
    /// @notice Maximum amount a single mint() call can create (0 = unlimited)
    uint256 public immutable mintLimit;

    /// @param _name  Token name
    /// @param _symbol Token symbol
    /// @param _mintLimit Maximum tokens allowed per mint call (0 means no limit)
    constructor(string memory _name, string memory _symbol, uint256 _mintLimit)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        Ownable(msg.sender)
    {
        mintLimit = _mintLimit; // e.g., 0 for Reward token, 100e18 for Staking token
    }

    /// @notice Mint tokens (owner or external faucet / demo)
    function mint(address to, uint256 amount) external {
        if (mintLimit != 0) {
            require(amount <= mintLimit, "amount exceeds mint limit");
        }
        _mint(to, amount);
    }
}