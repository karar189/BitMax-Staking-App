// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MockPriceOracle.sol";
import "./YieldTokenization.sol";

/**
 * @title YTAutoConverter
 * @dev Automatically converts YT tokens to PT tokens when a price threshold is reached
 */
contract YTAutoConverter is Ownable {
    using SafeERC20 for IERC20;

    MockPriceOracle public oracle;
    YieldTokenization public tokenization;
    address public stCoreToken;

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

    constructor(
        address _oracle,
        address _tokenization,
        address _stCoreToken
    ) Ownable(msg.sender) {
        oracle = MockPriceOracle(_oracle);
        tokenization = YieldTokenization(_tokenization);
        stCoreToken = _stCoreToken;
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
            oracle.setThreshold(stCoreToken, _thresholdPrice);
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
    function executeConversion(address user, uint256 maturity) external {
        UserConfig memory config = userConfigs[user];
        require(config.enabled, "Conversion not enabled");
        require(
            !conversionExecuted[user][maturity],
            "Conversion already executed"
        );

        // Check if threshold is reached
        require(oracle.thresholdReached(stCoreToken), "Threshold not reached");

        // Get YT and PT token addresses
        address ytToken = tokenization.ytTokens(maturity);
        address ptToken = tokenization.ptTokens(maturity);
        require(
            ytToken != address(0) && ptToken != address(0),
            "Invalid tokens"
        );

        // Get YT balance
        uint256 ytBalance = IERC20(ytToken).balanceOf(user);
        require(ytBalance > 0, "No YT balance");

        // Transfer YT tokens from user to this contract
        IERC20(ytToken).safeTransferFrom(user, address(this), ytBalance);

        // For a hackathon demo, we'll implement a simplified version:
        // 1. We burn YT tokens
        // 2. We mint an equivalent amount of PT tokens

        // Approve YT tokens for the tokenization contract (if needed)
        IERC20(ytToken).safeIncreaseAllowance(address(tokenization), ytBalance);

        // This is where the actual swap logic would be in a real implementation
        // For the hackathon, we simulate by transferring PT tokens we already have
        IERC20(ptToken).safeTransfer(user, ytBalance);

        // Mark conversion as executed
        conversionExecuted[user][maturity] = true;

        emit ConversionExecuted(user, maturity, ytBalance, ytBalance);
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
        return oracle.thresholdReached(stCoreToken);
    }

    /**
     * @dev Reset conversion status for testing
     * @param maturity Maturity timestamp
     */
    function resetConversionStatus(uint256 maturity) external {
        conversionExecuted[msg.sender][maturity] = false;
    }

    /**
     * @dev For hackathon demo only: deposits PT tokens for conversion testing
     * @param ptToken PT token address
     * @param amount Amount to deposit
     */
    function depositPTForDemo(address ptToken, uint256 amount) external {
        // In a real implementation, PT tokens would be acquired through swapping on a market
        // For demo purposes only, accept PT tokens from the contract owner
        IERC20(ptToken).safeTransferFrom(msg.sender, address(this), amount);
    }
}
