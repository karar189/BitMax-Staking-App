// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SYlstBTC is ERC20, Ownable {
    address public lstBTCToken;
    
    constructor(address _lstBTCToken) 
        ERC20("Standardized Yield lstBTC", "SY-lstBTC")
        Ownable(msg.sender) 
    {
        lstBTCToken = _lstBTCToken;
    }
    
    // Wrap lstBTC tokens
    function wrap(uint256 amount) external {
        // For hackathon demo, we're simplifying this process
        // In a real implementation, we would transfer the lstBTC tokens
        
        // Mint SY tokens
        _mint(msg.sender, amount);
    }
    
    // Unwrap back to lstBTC
    function unwrap(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient SY balance");
        
        // Burn SY tokens
        _burn(msg.sender, amount);
    }
    
    // Get current yield rate
    function getYieldRate() external pure returns (uint256) {
        // This would be provided by an oracle or calculated from staking rewards
        return 300; // 3% as basis points
    }
}