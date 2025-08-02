// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingDapp.sol";

contract SYToken is ERC20, Ownable {
    StakingDapp public stakingDapp;
    
    constructor(address _stakingDapp) 
        ERC20("Staked CORE SY Token", "syCORE")
        Ownable(msg.sender) 
    {
        stakingDapp = StakingDapp(_stakingDapp);
    }
    
    // Wrap staked tokens - MODIFIED FOR HACKATHON DEMO
    function wrap(uint256 amount) external {
        // COMMENTED OUT FOR HACKATHON: 
        // require(stakingDapp.getStakedAmount(msg.sender) >= amount, "Insufficient staked balance");
        
        // In a real implementation, we would need to lock the staked position
        // For hackathon, we simulate this with direct minting
        
        // Mint SY tokens
        _mint(msg.sender, amount);
    }
    
    // Unwrap back to staked position
    function unwrap(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient SY balance");
        
        // Burn SY tokens
        _burn(msg.sender, amount);
        
        // In a real implementation, we would unlock the staked position
    }
    
    // Get current yield rate
    function getYieldRate() external view returns (uint256) {
        // This would be provided by an oracle or calculated from staking rewards
        return 500; // 5% as basis points
    }
}