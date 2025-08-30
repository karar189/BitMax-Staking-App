// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {GenericYieldTokenization} from "../core/GenericYieldTokenization.sol";
import {SimpleAMM} from "../infrastructure/SimpleAMM.sol";

/// @title YT Auto Converter
/// @notice Automatically converts YT tokens to PT tokens when price thresholds are reached
/// @dev Production-ready implementation with real market integration and proper security
contract YTAutoConverter is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Price oracle for threshold monitoring
    IPriceOracle public oracle;
    
    /// @notice Tokenization contract for PT/YT tokens
    GenericYieldTokenization public tokenization;
    
    /// @notice Reference token for price monitoring
    IERC20 public referenceToken;
    
    /// @notice AMM for token swapping
    SimpleAMM public amm;

    /// @notice Maximum slippage tolerance (in basis points)
    uint256 public constant MAX_SLIPPAGE = 500; // 5%

    /// @notice Conversion fee (in basis points)
    uint256 public conversionFee = 30; // 0.3%

    /// @notice Fee denominator
    uint256 public constant FEE_DENOMINATOR = 10000;

    // User configuration
    struct UserConfig {
        bool enabled;
        uint256 thresholdPrice; // Price threshold in USD (scaled by 10^8)
        uint256[] maturities; // Maturity timestamps to convert
    }

    // Mapping: user address => configuration
    mapping(address => UserConfig) public userConfigs;

    // Conversion status
    mapping(address => mapping(uint256 => bool)) public conversionExecuted; // user => maturity => executed

    // Events
    event ConversionExecuted(
        address indexed user,
        uint256 maturity,
        uint256 ytAmount,
        uint256 ptAmount
    );
    event UserConfigUpdated(
        address indexed user,
        bool enabled,
        uint256 thresholdPrice
    );
    event MaturityAdded(address indexed user, uint256 maturity);
    event MaturityRemoved(address indexed user, uint256 maturity);

    /// @notice Initialize the auto converter
    /// @param _oracle Price oracle address
    /// @param _tokenization Tokenization contract address
    /// @param _referenceToken Reference token for price monitoring
    /// @param _amm AMM contract for token swapping
    constructor(
        address _oracle,
        address _tokenization,
        address _referenceToken,
        address _amm
    ) Ownable(msg.sender) {
        require(_oracle != address(0), "Invalid oracle address");
        require(_tokenization != address(0), "Invalid tokenization address");
        require(_referenceToken != address(0), "Invalid reference token address");
        require(_amm != address(0), "Invalid AMM address");
        
        oracle = IPriceOracle(_oracle);
        tokenization = GenericYieldTokenization(_tokenization);
        referenceToken = IERC20(_referenceToken);
        amm = SimpleAMM(_amm);
    }

    /**
     * @dev Configure automatic conversion
     * @param _enabled Whether automatic conversion is enabled
     * @param _thresholdPrice Price threshold in USD (scaled by 10^8)
     */
    function configure(bool _enabled, uint256 _thresholdPrice) external {
        userConfigs[msg.sender].enabled = _enabled;
        userConfigs[msg.sender].thresholdPrice = _thresholdPrice;

        emit UserConfigUpdated(msg.sender, _enabled, _thresholdPrice);

        // Set oracle threshold if enabled
        if (_enabled) {
            oracle.setThreshold(address(referenceToken), _thresholdPrice);
        }
    }

    /**
     * @dev Add a maturity to convert
     * @param maturity Maturity timestamp
     */
    function addMaturity(uint256 maturity) external {
        address pt = tokenization.ptTokens(maturity);
        address yt = tokenization.ytTokens(maturity);

        require(pt != address(0) && yt != address(0), "Invalid maturity");

        // Check if maturity already exists
        UserConfig storage config = userConfigs[msg.sender];
        for (uint i = 0; i < config.maturities.length; i++) {
            if (config.maturities[i] == maturity) {
                revert("Maturity already added");
            }
        }

        // Add maturity
        config.maturities.push(maturity);
        conversionExecuted[msg.sender][maturity] = false;

        emit MaturityAdded(msg.sender, maturity);
    }

    /**
     * @dev Remove a maturity
     * @param maturity Maturity timestamp
     */
    function removeMaturity(uint256 maturity) external {
        UserConfig storage config = userConfigs[msg.sender];

        // Find and remove maturity
        bool found = false;
        for (uint i = 0; i < config.maturities.length; i++) {
            if (config.maturities[i] == maturity) {
                // Replace with last element and pop
                config.maturities[i] = config.maturities[
                    config.maturities.length - 1
                ];
                config.maturities.pop();
                found = true;
                break;
            }
        }

        require(found, "Maturity not found");
        emit MaturityRemoved(msg.sender, maturity);
    }

    /**
     * @dev Get user's configured maturities
     * @param user User address
     * @return List of maturity timestamps
     */
    function getUserMaturities(
        address user
    ) external view returns (uint256[] memory) {
        return userConfigs[user].maturities;
    }

    /**
     * @dev Execute conversion from YT to PT when threshold is reached
     * Can be called by the user or by a keeper/backend service
     * @param user User address
     * @param maturity Maturity timestamp
     */
    /// @notice Execute conversion from YT to PT using market mechanisms
    /// @param user User address
    /// @param maturity Maturity timestamp
    /// @param minPTAmount Minimum PT tokens to receive (slippage protection)
    /// @param deadline Transaction deadline
    function executeConversion(
        address user,
        uint256 maturity,
        uint256 minPTAmount,
        uint256 deadline
    ) external nonReentrant whenNotPaused {
        require(block.timestamp <= deadline, "Transaction expired");
        
        UserConfig memory config = userConfigs[user];
        require(config.enabled, "Conversion not enabled");
        require(!conversionExecuted[user][maturity], "Conversion already executed");

        // Check if threshold is reached
        require(oracle.thresholdReached(address(referenceToken)), "Threshold not reached");

        // Get YT and PT token addresses
        address ytToken = tokenization.ytTokens(maturity);
        address ptToken = tokenization.ptTokens(maturity);
        require(ytToken != address(0) && ptToken != address(0), "Invalid tokens");

        // Get YT balance
        uint256 ytBalance = IERC20(ytToken).balanceOf(user);
        require(ytBalance > 0, "No YT balance");

        // Calculate conversion fee
        uint256 feeAmount = (ytBalance * conversionFee) / FEE_DENOMINATOR;
        uint256 conversionAmount = ytBalance - feeAmount;

        // Transfer YT tokens from user
        IERC20(ytToken).safeTransferFrom(user, address(this), ytBalance);

        // Perform market-based conversion through AMM
        uint256 receivedPT = _performMarketConversion(
            ytToken,
            ptToken,
            conversionAmount,
            minPTAmount
        );

        // Transfer fee to contract owner (protocol fee)
        if (feeAmount > 0) {
            IERC20(ytToken).safeTransfer(owner(), feeAmount);
        }

        // Transfer PT tokens to user
        IERC20(ptToken).safeTransfer(user, receivedPT);

        // Mark conversion as executed
        conversionExecuted[user][maturity] = true;

        emit ConversionExecuted(user, maturity, ytBalance, receivedPT);
    }

    /// @notice Internal function to perform market-based conversion
    /// @param ytToken YT token address
    /// @param ptToken PT token address
    /// @param amount Amount to convert
    /// @param minOutput Minimum output amount
    /// @return Amount of PT tokens received
    function _performMarketConversion(
        address ytToken,
        address ptToken,
        uint256 amount,
        uint256 minOutput
    ) internal returns (uint256) {
        // Approve AMM to spend YT tokens
        IERC20(ytToken).safeApprove(address(amm), amount);

        // Check if AMM has the required tokens as tokenA/tokenB
        if (address(amm.tokenA()) == ytToken && address(amm.tokenB()) == ptToken) {
            // Direct swap YT -> PT
            uint256 expectedOutput = amm.getAmountOut(amount, amm.reserveA(), amm.reserveB());
            require(expectedOutput >= minOutput, "Insufficient output amount");
            
            uint256 balanceBefore = IERC20(ptToken).balanceOf(address(this));
            amm.swapAforB(amount);
            uint256 balanceAfter = IERC20(ptToken).balanceOf(address(this));
            
            return balanceAfter - balanceBefore;
        } else if (address(amm.tokenB()) == ytToken && address(amm.tokenA()) == ptToken) {
            // Reverse swap YT -> PT
            uint256 expectedOutput = amm.getAmountOut(amount, amm.reserveB(), amm.reserveA());
            require(expectedOutput >= minOutput, "Insufficient output amount");
            
            uint256 balanceBefore = IERC20(ptToken).balanceOf(address(this));
            amm.swapBforA(amount);
            uint256 balanceAfter = IERC20(ptToken).balanceOf(address(this));
            
            return balanceAfter - balanceBefore;
        } else {
            revert("AMM does not support this token pair");
        }
    }

    /**
     * @dev Check if conversion can be executed
     * @param user User address
     * @param maturity Maturity timestamp
     * @return canExecute Whether conversion can be executed
     */
    function canExecuteConversion(
        address user,
        uint256 maturity
    ) external view returns (bool) {
        UserConfig memory config = userConfigs[user];

        if (!config.enabled || conversionExecuted[user][maturity]) {
            return false;
        }

        // Check if threshold is reached
        return oracle.thresholdReached(address(referenceToken));
    }

    /// @notice Update conversion fee
    /// @param newFee New fee in basis points
    function setConversionFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high"); // Max 10%
        uint256 oldFee = conversionFee;
        conversionFee = newFee;
        emit ConversionFeeUpdated(oldFee, newFee);
    }

    /// @notice Update AMM contract
    /// @param newAMM New AMM contract address
    function setAMM(address newAMM) external onlyOwner {
        require(newAMM != address(0), "Invalid AMM address");
        address oldAMM = address(amm);
        amm = SimpleAMM(newAMM);
        emit AMMUpdated(oldAMM, newAMM);
    }

    /// @notice Update price oracle
    /// @param newOracle New oracle contract address
    function setOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address");
        address oldOracle = address(oracle);
        oracle = IPriceOracle(newOracle);
        emit OracleUpdated(oldOracle, newOracle);
    }

    /// @notice Emergency function to reset conversion status (owner only)
    /// @param user User address
    /// @param maturity Maturity timestamp
    function emergencyResetConversion(address user, uint256 maturity) external onlyOwner {
        conversionExecuted[user][maturity] = false;
        emit ConversionReset(user, maturity);
    }

    /// @notice Emergency withdrawal of tokens (owner only)
    /// @param token Token address
    /// @param amount Amount to withdraw
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit EmergencyWithdrawal(token, amount);
    }

    /// @notice Pause all conversions
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause all conversions
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Additional events for production functionality
    event ConversionFeeUpdated(uint256 oldFee, uint256 newFee);
    event AMMUpdated(address oldAMM, address newAMM);
    event OracleUpdated(address oldOracle, address newOracle);
    event ConversionReset(address indexed user, uint256 maturity);
    event EmergencyWithdrawal(address indexed token, uint256 amount);
}
