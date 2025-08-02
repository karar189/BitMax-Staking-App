// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// This simulates a liquid staked Bitcoin token for hackathon purposes
contract MockLiquidStakedBTC is ERC20, Ownable {
    constructor() ERC20("Liquid Staked BTC", "lstBTC") Ownable(msg.sender) {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    // Get yield rate (simulated)
    function getYieldRate() external pure returns (uint256) {
        return 300; // 3% APY in basis points
    }
}