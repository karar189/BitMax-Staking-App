// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../tokens/PTToken.sol";
import "../tokens/YTToken.sol";

/// @title Generic Yield Tokenization Router
/// @notice Splits a standardized yield token (SY) into Principal (PT) and Yield (YT) tokens
contract GenericYieldTokenization is Ownable {
    IERC20 public syToken;
    string public baseName;
    string public baseSymbol;

    mapping(uint256 => address) public ptTokens;
    mapping(uint256 => address) public ytTokens;
    uint256[] public maturities;

    event TokensSplit(address indexed user, uint256 amount, uint256 indexed maturity);
    event TokensRedeemed(address indexed user, uint256 amount, uint256 indexed maturity);
    event MaturityCreated(uint256 indexed maturity, address pt, address yt);

    constructor(address _syToken, string memory _baseName, string memory _baseSymbol) Ownable(msg.sender) {
        syToken = IERC20(_syToken);
        baseName = _baseName;
        baseSymbol = _baseSymbol;
        createMaturity(block.timestamp + 30 days);
    }

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

    function split(uint256 amount, uint256 maturity) external {
        require(ptTokens[maturity] != address(0), "bad maturity");
        syToken.transferFrom(msg.sender, address(this), amount);
        PTToken(ptTokens[maturity]).mint(msg.sender, amount);
        YTToken(ytTokens[maturity]).mint(msg.sender, amount);
        emit TokensSplit(msg.sender, amount, maturity);
    }

    function redeem(uint256 amount, uint256 maturity) external {
        require(block.timestamp >= maturity, "not mature");
        PTToken pt = PTToken(ptTokens[maturity]);
        require(pt.balanceOf(msg.sender) >= amount, "no PT");
        pt.burnFrom(msg.sender, amount);
        syToken.transfer(msg.sender, amount);
        emit TokensRedeemed(msg.sender, amount, maturity);
    }

    function getMaturities() external view returns (uint256[] memory) {
        return maturities;
    }
}