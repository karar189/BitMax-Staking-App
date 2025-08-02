// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Yield Token (YT)
/// @notice ERC20 capturing all future yield until maturity
contract YTToken is ERC20, Ownable {
    uint256 public immutable maturity;

    event TokenMinted(address indexed to, uint256 amount);
    event TokenBurned(address indexed from, uint256 amount);

    constructor(string memory name, string memory symbol, uint256 _maturity)
        ERC20(name, symbol)
        Ownable(msg.sender)
    {
        maturity = _maturity;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokenMinted(to, amount);
    }

    function burnFrom(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
        emit TokenBurned(account, amount);
    }
}