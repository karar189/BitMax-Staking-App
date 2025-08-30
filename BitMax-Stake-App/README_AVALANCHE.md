# BitMax Staking App - Avalanche Fuji Deployment

This repository contains a complete yield tokenization system deployed on Avalanche Fuji testnet, implementing the 1:1 split mechanism for Principal Tokens (PT) and Yield Tokens (YT).

## 🏗️ Architecture Overview

The system consists of several interconnected contracts that work together to provide:

1. **Token Wrapping**: Convert yield-bearing tokens (stAVAX) into standardized SY tokens
2. **Yield Tokenization**: Split SY tokens into PT (Principal) and YT (Yield) tokens
3. **Trading**: AMM-based trading for PT and YT tokens
4. **Auto-Conversion**: Automatic YT → PT conversion based on oracle signals
5. **Staking**: LP staking and reward distribution

## 📋 Contract Deployment Order

### 1. Base Tokens
- **MockERC20 (stAVAX)**: Mock staked AVAX with 8% APY
- **MockERC20 (USDC.e)**: Mock USDC on Avalanche with 5% APY

### 2. Core Infrastructure
- **StandardizedTokenWrapper**: Wraps underlying tokens into SY
- **GenericYieldTokenization**: Core contract for PT/YT splitting
- **Maturities**: Auto-deploys PT and YT ERC20 tokens

### 3. Trading & Liquidity
- **SimpleAMM**: AMM for PT ↔ USDC.e and YT ↔ USDC.e trading
- **ProductionPriceOracle**: Price feeds and threshold monitoring

### 4. Advanced Features
- **YTAutoConverter**: Auto-converts YT → PT based on oracle signals
- **StakingDapp**: LP staking and reward distribution

## 🚀 Quick Start

### Prerequisites
- Node.js 16+ and npm
- Avalanche Fuji testnet AVAX (get from [faucet](https://faucet.avax.network/))
- Private key for deployment

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Private Key
```bash
# Copy template and edit
cp secret.template.json secret.json
nano secret.json
```

Add your private key:
```json
{
  "PrivateKey": "0x1234567890abcdef..."
}
```

### 3. Compile Contracts
```bash
npm run compile
```

### 4. Deploy to Avalanche Fuji
```bash
npm run deploy:avalanche
```

### 5. Test Deployment
```bash
npm run test:avalanche
```

## 🔧 Configuration

### Network Settings
- **Network**: Avalanche Fuji Testnet
- **Chain ID**: 43113
- **RPC URL**: https://api.avax-test.network/ext/bc/C/rpc
- **Explorer**: https://testnet.snowtrace.io/
- **Gas Price**: 25 gwei

### Contract Parameters
- **stAVAX APY**: 8% (800 basis points)
- **USDC.e APY**: 5% (500 basis points)
- **Maturities**: 3-month and 6-month
- **Auto-conversion threshold**: 50% (5000 basis points)

## 📊 Contract Addresses

After deployment, all contract addresses are saved to `deployment-avalanche.json`:

```json
{
  "network": "avalanche_fuji",
  "deployer": "0x...",
  "contracts": {
    "mockStAVAX": "0x...",
    "mockUSDCE": "0x...",
    "syWrapper": "0x...",
    "yieldTokenization": "0x...",
    "ptToken": "0x...",
    "ytToken": "0x...",
    "ptAmm": "0x...",
    "ytAmm": "0x...",
    "priceOracle": "0x...",
    "ytAutoConverter": "0x...",
    "stakingDapp": "0x..."
  }
}
```

## 🧪 Testing the System

### 1. Token Wrapping
```javascript
// Wrap stAVAX → SY
await stAVAX.approve(syWrapper.address, amount);
await syWrapper.wrap([amount]);
```

### 2. Yield Tokenization
```javascript
// Split SY → PT + YT
await syWrapper.approve(yieldTokenization.address, amount);
await yieldTokenization.split(amount, maturityTimestamp);
```

### 3. AMM Trading
```javascript
// Add liquidity
await ptToken.approve(ptAmm.address, amount);
await usdce.approve(ptAmm.address, amount);
await ptAmm.addLiquidity(amount, amount);
```

### 4. Auto-Conversion
```javascript
// Enable auto-conversion
await ytAutoConverter.updateUserConfig(true, thresholdPrice);
```

## 🔍 Verification

### Contract Verification
```bash
# Get API key from Snowtrace
npx hardhat verify --network avalanche_fuji CONTRACT_ADDRESS [ARGS]
```

### Manual Testing
1. **Token Operations**: Mint, transfer, wrap, split
2. **AMM Functions**: Add liquidity, swap tokens
3. **Oracle Functions**: Update prices, check thresholds
4. **Auto-Conversion**: Trigger conversion based on oracle signals

## 📈 Gas Optimization

- **Total Deployment**: ~0.1-0.2 AVAX
- **Gas Price**: 25 gwei (configurable)
- **Optimizations**: Enabled compiler optimizations (200 runs)

## 🛡️ Security Features

- **Access Control**: Ownable pattern for admin functions
- **Pausable**: Emergency pause functionality
- **Reentrancy Protection**: Guards against reentrancy attacks
- **Circuit Breaker**: Oracle circuit breaker for price anomalies
- **Threshold Monitoring**: Price threshold validation

## 🔄 Integration Points

### Frontend Integration
Update your frontend with contract addresses from `deployment-avalanche.json`

### Backend Services
- Monitor oracle health
- Track threshold events
- Execute auto-conversions
- Manage liquidity pools

## 🚨 Troubleshooting

### Common Issues
1. **Insufficient Gas**: Ensure >0.1 AVAX balance
2. **Private Key Format**: Must be 64-character hex string
3. **Network Connection**: Verify Fuji testnet connection
4. **Contract Verification**: Check constructor arguments

### Debug Commands
```bash
# Check network
npx hardhat console --network avalanche_fuji

# Verify deployment
npx hardhat run scripts/test-deployment.js --network avalanche_fuji

# Check contract state
npx hardhat run scripts/debug-contracts.js --network avalanche_fuji
```

## 📚 Additional Resources

- [Avalanche Documentation](https://docs.avax.network/)
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Yield Tokenization Guide](https://docs.euler.finance/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section
2. Review contract logs
3. Verify network configuration
4. Test with minimal amounts first

---

**⚠️ Important**: This is a testnet deployment. Never use real funds or mainnet private keys. 