// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Generic Standardized Yield (SY) Token
/// @notice Wraps any interest-bearing token to standardize yield tokenization
contract GenericSYToken is ERC20, Ownable {
    IERC20 public underlying;
    uint256 public yieldRateBps;   // e.g. 500 = 5%
    bool public productionMode;

    event Wrapped(address indexed user, uint256 amount);
    event Unwrapped(address indexed user, uint256 amount);
    event YieldRateUpdated(uint256 oldRate, uint256 newRate);
    event ProductionModeSet(bool enabled);

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint256 _yieldRateBps,
        bool _productionMode
    ) ERC20(_name, _symbol) Ownable(msg.sender) {
        underlying = IERC20(_underlying);
        yieldRateBps = _yieldRateBps;
        productionMode = _productionMode;
    }

    function wrap(uint256 amount) external {
        if (productionMode) {
            underlying.transferFrom(msg.sender, address(this), amount);
        }
        _mint(msg.sender, amount);
        emit Wrapped(msg.sender, amount);
    }

    function unwrap(uint256 amount) external {
        _burn(msg.sender, amount);
        if (productionMode) {
            underlying.transfer(msg.sender, amount);
        }
        emit Unwrapped(msg.sender, amount);
    }

    function setYieldRate(uint256 newRate) external onlyOwner {
        uint256 old = yieldRateBps;
        yieldRateBps = newRate;
        emit YieldRateUpdated(old, newRate);
    }

    function setProductionMode(bool on) external onlyOwner {
        productionMode = on;
        emit ProductionModeSet(on);
    }

    function getYieldRate() external view returns (uint256) {
        return yieldRateBps;
    }
}