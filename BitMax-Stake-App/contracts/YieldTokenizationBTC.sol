// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SYlstBTC.sol";

contract YieldTokenizationBTC is Ownable {
    SYlstBTC public syToken;
    
    // PT and YT tokens
    mapping(uint256 => address) public ptTokens; // maturity timestamp -> token address
    mapping(uint256 => address) public ytTokens; // maturity timestamp -> token address
    
    // Available maturity dates
    uint256[] public maturities;
    
    event TokensSplit(address indexed user, uint256 amount, uint256 maturity);
    event TokensRedeemed(address indexed user, uint256 amount, uint256 maturity);
    
    constructor(address _syToken) Ownable(msg.sender) {
        syToken = SYlstBTC(_syToken);
        
        // Create 30-day maturity
        createMaturity(block.timestamp + 30 days);
    }
    
    // Create new maturity option
    function createMaturity(uint256 maturityTimestamp) public onlyOwner {
        require(maturityTimestamp > block.timestamp, "Maturity must be in future");
        
        // Deploy new PT token for lstBTC
        PTTokenBTC pt = new PTTokenBTC("PT lstBTC", "PT-lstBTC", maturityTimestamp);
        
        // Deploy new YT token for lstBTC
        YTTokenBTC yt = new YTTokenBTC("YT lstBTC", "YT-lstBTC", maturityTimestamp);
        
        // Store token addresses
        ptTokens[maturityTimestamp] = address(pt);
        ytTokens[maturityTimestamp] = address(yt);
        maturities.push(maturityTimestamp);
    }
    
    // Split SY tokens into PT and YT
    function split(uint256 amount, uint256 maturity) external {
        require(ptTokens[maturity] != address(0), "Invalid maturity");
        require(syToken.balanceOf(msg.sender) >= amount, "Insufficient SY balance");
        
        // Transfer SY tokens to this contract
        syToken.transferFrom(msg.sender, address(this), amount);
        
        // Mint PT and YT tokens to user
        PTTokenBTC(ptTokens[maturity]).mint(msg.sender, amount);
        YTTokenBTC(ytTokens[maturity]).mint(msg.sender, amount);
        
        emit TokensSplit(msg.sender, amount, maturity);
    }
    
    // Redeem PT tokens at maturity
    function redeem(uint256 amount, uint256 maturity) external {
        require(block.timestamp >= maturity, "Not yet mature");
        require(ptTokens[maturity] != address(0), "Invalid maturity");
        
        PTTokenBTC pt = PTTokenBTC(ptTokens[maturity]);
        require(pt.balanceOf(msg.sender) >= amount, "Insufficient PT balance");
        
        // Burn PT tokens
        pt.burnFrom(msg.sender, amount);
        
        // Transfer SY tokens back to user
        syToken.transfer(msg.sender, amount);
        
        emit TokensRedeemed(msg.sender, amount, maturity);
    }
    
    // Get available maturities
    function getMaturities() external view returns (uint256[] memory) {
        return maturities;
    }
}

// Principal Token for BTC
contract PTTokenBTC is ERC20, Ownable {
    uint256 public maturity;
    
    constructor(string memory name, string memory symbol, uint256 _maturity) 
        ERC20(name, symbol)
        Ownable(msg.sender) 
    {
        maturity = _maturity;
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

// Yield Token for BTC
contract YTTokenBTC is ERC20, Ownable {
    uint256 public maturity;
    
    constructor(string memory name, string memory symbol, uint256 _maturity) 
        ERC20(name, symbol)
        Ownable(msg.sender) 
    {
        maturity = _maturity;
    }
    
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}