// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PTToken} from "./PTToken.sol";
import {YTToken} from "./YTToken.sol";

/// @title USDC Yield Tokenization Router for Avalanche
/// @notice Splits USDC deposits into Principal (PT) and Yield (YT) tokens
/// @dev Simplified for hackathon - focuses on core functionality without complex wrapper layer
contract USDCYieldTokenization is Ownable, Pausable, ReentrancyGuard {
    /// @notice The USDC token being managed
    IERC20 public immutable usdcToken;

    /// @notice Default maturity duration (30 days)
    uint256 public constant DEFAULT_MATURITY_DURATION = 30 days;

    /// @notice Mapping from maturity timestamp to PT token address
    mapping(uint256 => address) public ptTokens;

    /// @notice Mapping from maturity timestamp to YT token address
    mapping(uint256 => address) public ytTokens;

    /// @notice List of all maturity timestamps
    uint256[] public maturities;

    /// @notice Total USDC deposited in the protocol
    uint256 public totalDeposited;

    /// @notice Events
    event Deposited(address indexed user, uint256 amount, uint256 indexed maturity);
    event PTRedeemed(address indexed user, uint256 amount, uint256 indexed maturity);
    event YTRedeemed(address indexed user, uint256 amount, uint256 indexed maturity);
    event MaturityCreated(uint256 indexed maturity, address pt, address yt);

    /// @notice Initialize the contract with USDC token address
    /// @param _usdcToken Address of the USDC token on Avalanche
    constructor(address _usdcToken) Ownable(msg.sender) {
        require(_usdcToken != address(0), "Invalid USDC token");
        usdcToken = IERC20(_usdcToken);
        
        // Create initial maturity (30 days from now)
        createMaturity(block.timestamp + DEFAULT_MATURITY_DURATION);
    }

    /// @notice Creates a new maturity date with corresponding PT and YT tokens
    /// @param maturity The timestamp for the new maturity
    function createMaturity(uint256 maturity) public onlyOwner {
        require(maturity > block.timestamp, "Maturity must be in future");
        require(ptTokens[maturity] == address(0), "Maturity already exists");

        PTToken pt = new PTToken(
            string.concat("PT USDC-", _timestampToString(maturity)), 
            string.concat("PT-USDC-", _timestampToString(maturity)), 
            maturity
        );
        YTToken yt = new YTToken(
            string.concat("YT USDC-", _timestampToString(maturity)), 
            string.concat("YT-USDC-", _timestampToString(maturity)), 
            maturity
        );

        ptTokens[maturity] = address(pt);
        ytTokens[maturity] = address(yt);
        maturities.push(maturity);

        emit MaturityCreated(maturity, address(pt), address(yt));
    }

    /// @notice Deposit USDC and receive PT + YT tokens
    /// @param amount Amount of USDC to deposit (in USDC units with 6 decimals)
    /// @param maturity Maturity timestamp for the tokens (0 for default next maturity)
    function deposit(uint256 amount, uint256 maturity) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        // Use default maturity if not specified
        if (maturity == 0) {
            maturity = getNextMaturity();
        }
        
        require(ptTokens[maturity] != address(0), "Invalid maturity");
        require(maturity > block.timestamp, "Maturity must be in future");
        
        // Transfer USDC from user
        usdcToken.transferFrom(msg.sender, address(this), amount);
        
        // Mint PT and YT tokens (1:1 ratio with deposited amount)
        PTToken(ptTokens[maturity]).mint(msg.sender, amount);
        YTToken(ytTokens[maturity]).mint(msg.sender, amount);
        
        totalDeposited += amount;
        emit Deposited(msg.sender, amount, maturity);
    }

    /// @notice Convenience function to deposit with default maturity
    /// @param amount Amount of USDC to deposit
    function deposit(uint256 amount) external {
        deposit(amount, 0);
    }

    /// @notice Redeem mature PT tokens for USDC
    /// @param amount Amount of PT tokens to redeem
    /// @param maturity Maturity timestamp of the tokens
    function redeemPT(uint256 amount, uint256 maturity) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(block.timestamp >= maturity, "Not yet mature");
        
        PTToken pt = PTToken(ptTokens[maturity]);
        require(pt.balanceOf(msg.sender) >= amount, "Insufficient PT balance");
        
        // Burn PT tokens and return USDC
        pt.burnFrom(msg.sender, amount);
        usdcToken.transfer(msg.sender, amount);
        
        totalDeposited -= amount;
        emit PTRedeemed(msg.sender, amount, maturity);
    }

    /// @notice Redeem YT tokens (simplified for hackathon - just burns them)
    /// @param amount Amount of YT tokens to redeem
    /// @param maturity Maturity timestamp of the tokens
    /// @dev For hackathon: YT redemption just burns tokens without yield calculation
    function redeemYT(uint256 amount, uint256 maturity) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        YTToken yt = YTToken(ytTokens[maturity]);
        require(yt.balanceOf(msg.sender) >= amount, "Insufficient YT balance");
        
        // For hackathon: just burn YT tokens (no yield distribution)
        yt.burnFrom(msg.sender, amount);
        
        emit YTRedeemed(msg.sender, amount, maturity);
    }

    /// @notice Get the next available maturity timestamp
    /// @return Next maturity timestamp
    function getNextMaturity() public view returns (uint256) {
        if (maturities.length == 0) {
            return block.timestamp + DEFAULT_MATURITY_DURATION;
        }
        
        // Find the earliest maturity that's still in the future
        for (uint256 i = 0; i < maturities.length; i++) {
            if (maturities[i] > block.timestamp) {
                return maturities[i];
            }
        }
        
        // If no future maturities, create a new one
        return block.timestamp + DEFAULT_MATURITY_DURATION;
    }

    /// @notice Get all available maturity timestamps
    /// @return Array of maturity timestamps
    function getMaturities() external view returns (uint256[] memory) {
        return maturities;
    }

    /// @notice Get PT and YT token addresses for a maturity
    /// @param maturity Maturity timestamp
    /// @return pt PT token address
    /// @return yt YT token address
    function getTokens(uint256 maturity) external view returns (address pt, address yt) {
        return (ptTokens[maturity], ytTokens[maturity]);
    }

    /// @notice Get user's token balances for a maturity
    /// @param user User address
    /// @param maturity Maturity timestamp
    /// @return ptBalance PT token balance
    /// @return ytBalance YT token balance
    function getUserBalances(address user, uint256 maturity) external view returns (uint256 ptBalance, uint256 ytBalance) {
        address ptAddr = ptTokens[maturity];
        address ytAddr = ytTokens[maturity];
        
        if (ptAddr != address(0)) {
            ptBalance = PTToken(ptAddr).balanceOf(user);
        }
        if (ytAddr != address(0)) {
            ytBalance = YTToken(ytAddr).balanceOf(user);
        }
    }

    /// @notice Convert timestamp to string for token naming
    /// @param timestamp Timestamp to convert
    /// @return String representation of timestamp
    function _timestampToString(uint256 timestamp) internal pure returns (string memory) {
        return string(abi.encodePacked(timestamp));
    }

    /// @notice Emergency function to withdraw USDC (owner only)
    /// @param amount Amount to withdraw
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= usdcToken.balanceOf(address(this)), "Insufficient balance");
        usdcToken.transfer(owner(), amount);
    }

    /// @notice Pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Get contract status information
    /// @return contractBalance USDC balance of the contract
    /// @return totalMaturities Number of maturities created
    /// @return isPaused Whether contract is paused
    function getContractInfo() external view returns (uint256 contractBalance, uint256 totalMaturities, bool isPaused) {
        return (
            usdcToken.balanceOf(address(this)),
            maturities.length,
            paused()
        );
    }
}