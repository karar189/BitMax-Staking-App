// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {StandardizedTokenWrapper} from "../tokens/StandardizedTokenWrapper.sol";
import {PTToken} from "../tokens/PTToken.sol";
import {YTToken} from "../tokens/YTToken.sol";

/// @title Generic Yield Tokenization Router
/// @notice Splits a standardized yield token (SY) into Principal (PT) and Yield (YT) tokens
/// @dev Implements Pausable and ReentrancyGuard for security, and uses named imports for better code clarity
contract GenericYieldTokenization is Ownable, Pausable, ReentrancyGuard {
    /// @notice The standardized yield token being split
    /// @dev This token is wrapped and split into PT and YT tokens
    StandardizedTokenWrapper public syToken;

    /// @notice Base name used for creating PT and YT token names
    /// @dev Combined with "PT " or "YT " prefix when creating new tokens
    string public baseName;

    /// @notice Base symbol used for creating PT and YT token symbols
    /// @dev Combined with "PT-" or "YT-" prefix when creating new tokens
    string public baseSymbol;

    /// @notice Mapping from maturity timestamp to PT token address
    /// @dev Used to track all PT tokens created for different maturities
    mapping(uint256 => address) public ptTokens;

    /// @notice Mapping from maturity timestamp to YT token address
    /// @dev Used to track all YT tokens created for different maturities
    mapping(uint256 => address) public ytTokens;

    /// @notice List of all maturity timestamps
    /// @dev Used to track and iterate over all available maturities
    uint256[] public maturities;

    /// @notice Emitted when tokens are split into PT and YT
    /// @param user The address of the user who split the tokens
    /// @param amount The amount of tokens split
    /// @param maturity The maturity timestamp for the split tokens
    event TokensSplit(address indexed user, uint256 amount, uint256 indexed maturity);

    /// @notice Emitted when PT tokens are redeemed for the underlying SY token
    /// @param user The address of the user who redeemed the tokens
    /// @param amount The amount of tokens redeemed
    /// @param maturity The maturity timestamp of the redeemed tokens
    event TokensRedeemed(address indexed user, uint256 amount, uint256 indexed maturity);

    /// @notice Emitted when a new maturity date is created with corresponding PT and YT tokens
    /// @param maturity The timestamp for the new maturity
    /// @param pt The address of the created PT token
    /// @param yt The address of the created YT token
    event MaturityCreated(uint256 indexed maturity, address pt, address yt);

    /// @notice Emitted when the contract is paused
    event ContractPaused(address indexed by);

    /// @notice Emitted when the contract is unpaused
    event ContractUnpaused(address indexed by);

    /// @notice Initializes the contract with the underlying SY token and naming parameters
    /// @param _syToken The address of the standardized yield token
    /// @param _baseName The base name for PT and YT tokens
    /// @param _baseSymbol The base symbol for PT and YT tokens
    constructor(address _syToken, string memory _baseName, string memory _baseSymbol) 
        Ownable(msg.sender) 
    {
        require(_syToken != address(0), "Invalid SY token");
        syToken = StandardizedTokenWrapper(_syToken);
        baseName = _baseName;
        baseSymbol = _baseSymbol;
        createMaturity(block.timestamp + 30 days);
    }

    /// @notice Creates a new maturity date with corresponding PT and YT tokens
    /// @param maturity The timestamp for the new maturity
    /// @dev Only callable by owner, creates new PT and YT token contracts
    function createMaturity(uint256 maturity) public onlyOwner {
        require(maturity > block.timestamp, "future maturity only");
        require(ptTokens[maturity] == address(0), "exists");

        PTToken pt = new PTToken(string.concat("PT ", baseName), string.concat("PT-", baseSymbol), maturity);
        YTToken yt = new YTToken(string.concat("YT ", baseName), string.concat("YT-", baseSymbol), maturity);

        ptTokens[maturity] = address(pt);
        ytTokens[maturity] = address(yt);
        maturities.push(maturity);

        emit MaturityCreated(maturity, address(pt), address(yt));
    }

    /// @notice Splits SY tokens into corresponding PT and YT tokens
    /// @param amount The amount of SY tokens to split
    /// @param maturity The maturity timestamp to split into
    /// @dev Requires contract to be unpaused and protects against reentrancy
    function split(uint256 amount, uint256 maturity) external nonReentrant whenNotPaused {
        require(amount > 0, "amount must be > 0");
        require(ptTokens[maturity] != address(0), "bad maturity");
        
        syToken.transferFrom(msg.sender, address(this), amount);
        PTToken(ptTokens[maturity]).mint(msg.sender, amount);
        YTToken(ytTokens[maturity]).mint(msg.sender, amount);
        
        emit TokensSplit(msg.sender, amount, maturity);
    }

    /// @notice Redeems mature PT tokens for the underlying SY token
    /// @param amount The amount of PT tokens to redeem
    /// @param maturity The maturity timestamp of the tokens
    /// @dev Requires contract to be unpaused and protects against reentrancy
    function redeem(uint256 amount, uint256 maturity) external nonReentrant whenNotPaused {
        require(amount > 0, "amount must be > 0");
        require(block.timestamp >= maturity, "not mature");
        
        PTToken pt = PTToken(ptTokens[maturity]);
        require(pt.balanceOf(msg.sender) >= amount, "no PT");
        
        pt.burnFrom(msg.sender, amount);
        syToken.transfer(msg.sender, amount);
        
        emit TokensRedeemed(msg.sender, amount, maturity);
    }

    /// @notice Returns all available maturity timestamps
    /// @return Array of maturity timestamps
    function getMaturities() external view returns (uint256[] memory) {
        return maturities;
    }

    /// @notice Pauses all non-view functions
    /// @dev Only callable by owner
    function pause() external onlyOwner {
        _pause();
        emit ContractPaused(msg.sender);
    }

    /// @notice Unpauses all non-view functions
    /// @dev Only callable by owner
    function unpause() external onlyOwner {
        _unpause();
        emit ContractUnpaused(msg.sender);
    }
}