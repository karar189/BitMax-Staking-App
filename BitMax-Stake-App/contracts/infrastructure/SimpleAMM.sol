// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Simple Automated Market Maker
/// @notice Provides basic AMM functionality for PT/YT token pairs
/// @dev Implements constant product formula with fee mechanism
contract SimpleAMM is Ownable, Pausable, ReentrancyGuard {
    /// @notice Token A in the pair (usually PT or YT token)
    IERC20 public tokenA;
    
    /// @notice Token B in the pair (usually reward token or stable)
    IERC20 public tokenB;
    
    /// @notice Current reserve of token A
    uint256 public reserveA;
    
    /// @notice Current reserve of token B
    uint256 public reserveB;
    
    /// @notice Denominator for fee calculation (fee/FEE_DENOMINATOR)
    uint256 public constant FEE_DENOMINATOR = 1000;
    
    /// @notice Current fee rate (3 = 0.3%)
    uint256 public fee = 3;
    
    /// @notice Emitted when a swap occurs
    /// @param user Address performing the swap
    /// @param amountIn Amount of input token
    /// @param amountOut Amount of output token
    /// @param isAtoB True if swapping A for B, false if B for A
    event Swap(address indexed user, uint256 amountIn, uint256 amountOut, bool isAtoB);
    
    /// @notice Emitted when liquidity is added
    /// @param user Address adding liquidity
    /// @param amountA Amount of token A added
    /// @param amountB Amount of token B added
    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB);
    
    /// @notice Emitted when fee rate is updated
    /// @param oldFee Previous fee rate
    /// @param newFee New fee rate
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    
    /// @notice Emitted when contract is paused
    event AMMPaused(address indexed by);
    
    /// @notice Emitted when contract is unpaused
    event AMMUnpaused(address indexed by);
    
    /// @notice Initializes the AMM with token pair
    /// @param _tokenA Address of token A
    /// @param _tokenB Address of token B
    constructor(address _tokenA, address _tokenB) Ownable(msg.sender) {
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");
        require(_tokenA != _tokenB, "Identical tokens");
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    /// @notice Adds initial liquidity to the pool
    /// @param amountA Amount of token A to add
    /// @param amountB Amount of token B to add
    /// @dev Requires contract to be unpaused and protects against reentrancy
    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant whenNotPaused {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");
        
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        
        reserveA += amountA;
        reserveB += amountB;
        
        emit LiquidityAdded(msg.sender, amountA, amountB);
    }
    
    /// @notice Swaps token A for token B
    /// @param amountIn Amount of token A to swap
    /// @dev Requires contract to be unpaused and protects against reentrancy
    function swapAforB(uint256 amountIn) external nonReentrant whenNotPaused {
        require(amountIn > 0, "Amount must be greater than 0");
        
        uint256 amountOut = getAmountOut(amountIn, reserveA, reserveB);
        require(amountOut > 0, "Insufficient output amount");
        require(amountOut <= reserveB, "Insufficient liquidity");
        
        tokenA.transferFrom(msg.sender, address(this), amountIn);
        tokenB.transfer(msg.sender, amountOut);
        
        reserveA += amountIn;
        reserveB -= amountOut;
        
        emit Swap(msg.sender, amountIn, amountOut, true);
    }
    
    /// @notice Swaps token B for token A
    /// @param amountIn Amount of token B to swap
    /// @dev Requires contract to be unpaused and protects against reentrancy
    function swapBforA(uint256 amountIn) external nonReentrant whenNotPaused {
        require(amountIn > 0, "Amount must be greater than 0");
        
        uint256 amountOut = getAmountOut(amountIn, reserveB, reserveA);
        require(amountOut > 0, "Insufficient output amount");
        require(amountOut <= reserveA, "Insufficient liquidity");
        
        tokenB.transferFrom(msg.sender, address(this), amountIn);
        tokenA.transfer(msg.sender, amountOut);
        
        reserveB += amountIn;
        reserveA -= amountOut;
        
        emit Swap(msg.sender, amountIn, amountOut, false);
    }
    
    /// @notice Calculates output amount for a given input amount
    /// @param amountIn Amount of input token
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return Amount of output token
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public view returns (uint256) {
        require(amountIn > 0, "Invalid input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
        
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - fee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * FEE_DENOMINATOR + amountInWithFee;
        
        return numerator / denominator;
    }
    
    /// @notice Updates the swap fee
    /// @param newFee New fee value (3 = 0.3%)
    /// @dev Only callable by owner
    function setFee(uint256 newFee) external onlyOwner {
        require(newFee < FEE_DENOMINATOR, "Fee too high");
        uint256 oldFee = fee;
        fee = newFee;
        emit FeeUpdated(oldFee, newFee);
    }
    
    /// @notice Pauses all non-view functions
    /// @dev Only callable by owner
    function pause() external onlyOwner {
        _pause();
        emit AMMPaused(msg.sender);
    }
    
    /// @notice Unpauses all non-view functions
    /// @dev Only callable by owner
    function unpause() external onlyOwner {
        _unpause();
        emit AMMUnpaused(msg.sender);
    }
}