// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleAMM is Ownable {
    IERC20 public tokenA; // PT or YT token
    IERC20 public tokenB; // Often reward token or stable
    
    uint256 public reserveA;
    uint256 public reserveB;
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public fee = 3; // 0.3% fee
    
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isAtoB);
    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB);
    
    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    // Add initial liquidity
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }
    
    // Swap token A for token B (e.g., PT for Reward)
    function swapAforB(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0");
        
        uint256 amountOut = getAmountOut(amountIn, reserveA, reserveB);
        require(amountOut > 0, "Insufficient output amount");
        
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(msg.sender, amountOut);
        
        reserveA += amountIn;
        reserveB -= amountOut;
        
        emit Swap(msg.sender, amountIn, amountOut, true);
    }
    
    // Swap token B for token A (e.g., Reward for PT)
    function swapBforA(uint256 amountIn) external {
        require(amountIn > 0, "Amount must be greater than 0");
        
        uint256 amountOut = getAmountOut(amountIn, reserveB, reserveA);
        require(amountOut > 0, "Insufficient output amount");
        
        tokenB.transferFrom(msg.sender, address(this), amountIn);
        tokenA.transfer(msg.sender, amountOut);
        
        reserveB += amountIn;
        reserveA -= amountOut;
        
        emit Swap(msg.sender, amountIn, amountOut, false);
    }
    
    // Quote function
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public view returns (uint256) {
        require(amountIn > 0, "Amount in must be greater than 0");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        
        return numerator / denominator;
    }
}