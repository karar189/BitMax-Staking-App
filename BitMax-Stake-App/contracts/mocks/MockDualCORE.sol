// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// This simulates a dual staked token (CORE + BTC) for hackathon purposes
contract MockDualCORE is ERC20, Ownable {
    IERC20 public stCOREToken;
    IERC20 public lstBTCToken;
    
    // Ratio for conversion (can be adjusted based on your tokenomics)
    uint256 public constant RATIO_STCORE = 50; // 50% stCORE
    uint256 public constant RATIO_LSTBTC = 50; // 50% lstBTC
    
    constructor(address _stCOREToken, address _lstBTCToken) 
        ERC20("Dual Staked CORE", "dualCORE") 
        Ownable(msg.sender) 
    {
        stCOREToken = IERC20(_stCOREToken);
        lstBTCToken = IERC20(_lstBTCToken);
    }
    
    // Mint by providing both stCORE and lstBTC tokens
    function mintDual(uint256 amount) external {
        // Calculate required amounts of each token
        uint256 stCOREAmount = (amount * RATIO_STCORE) / 100;
        uint256 lstBTCAmount = (amount * RATIO_LSTBTC) / 100;
        
        // Check if user has enough of both tokens
        require(stCOREToken.balanceOf(msg.sender) >= stCOREAmount, "Insufficient stCORE balance");
        require(lstBTCToken.balanceOf(msg.sender) >= lstBTCAmount, "Insufficient lstBTC balance");
        
        // Transfer both tokens to this contract
        stCOREToken.transferFrom(msg.sender, address(this), stCOREAmount);
        lstBTCToken.transferFrom(msg.sender, address(this), lstBTCAmount);
        
        // Mint dualCORE tokens to the user
        _mint(msg.sender, amount);
    }
    
    // Function to redeem dualCORE back to original tokens
    function redeemDual(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient dualCORE balance");
        
        // Calculate amounts to return
        uint256 stCOREAmount = (amount * RATIO_STCORE) / 100;
        uint256 lstBTCAmount = (amount * RATIO_LSTBTC) / 100;
        
        // Burn dualCORE tokens
        _burn(msg.sender, amount);
        
        // Return the original tokens
        stCOREToken.transfer(msg.sender, stCOREAmount);
        lstBTCToken.transfer(msg.sender, lstBTCAmount);
    }
    
    // For demo/hackathon purposes - allows direct minting without actual tokens
    function demoMint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    // Get yield rate (simulated)
    function getYieldRate() external pure returns (uint256) {
        return 700; // 7% APY in basis points (higher than individual assets)
    }
}