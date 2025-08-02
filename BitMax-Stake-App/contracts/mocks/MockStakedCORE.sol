// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// This simulates a staked CORE token for hackathon purposes
contract MockStakedCORE is ERC20, Ownable {
    constructor() ERC20("Staked CORE", "stCORE") Ownable(msg.sender) {}
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    // Simplified staking functionality
    function stake(uint256 amount) external {
        // In a real implementation, this would take CORE tokens
        _mint(msg.sender, amount);
    }
    
    // Get yield rate (simulated)
    function getYieldRate() external pure returns (uint256) {
        return 500; // 5% APY in basis points
    }
}