# Avalanche Fuji Testnet Deployment Guide

This guide will walk you through deploying all the required contracts to Avalanche Fuji testnet for the 1:1 split yield tokenization system.

## Prerequisites

1. **Avalanche Fuji Testnet AVAX**: You need testnet AVAX for gas fees
2. **Private Key**: Your wallet's private key for deployment
3. **Node.js & npm**: For running the deployment scripts

## Getting Testnet AVAX

1. Visit [Avalanche Faucet](https://faucet.avax.network/)
2. Connect your wallet
3. Request testnet AVAX (you'll get 2 AVAX)

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Private Key

1. Copy `secret.template.json` to `secret.json`
2. Replace `YOUR_PRIVATE_KEY_HERE` with your actual private key
3. **⚠️ NEVER commit secret.json to git**

```json
{
  "PrivateKey": "0x1234567890abcdef..."
}
```

### 3. Compile Contracts

```bash
npm run compile
```

## Deployment

### Deploy All Contracts

```bash
npm run deploy:avalanche
```

This will deploy all contracts in the correct order:

1. **MockERC20** - Mock yield-bearing tokens (stAVAX, USDC.e)
2. **StandardizedTokenWrapper** - Wraps underlying tokens into SY
3. **GenericYieldTokenization** - Core contract for PT/YT splitting
4. **Maturities** - Auto-deploys PT + YT ERC20 tokens
5. **SimpleAMM** - AMM for trading PT ↔ YT and PT ↔ USDC.e
6. **ProductionPriceOracle** - Price feeds and threshold monitoring
7. **YTAutoConverter** - Auto-converts YT → PT based on oracle signals
8. **StakingDapp** - Staking system for LPs

## Contract Addresses

After deployment, addresses will be saved to `deployment-avalanche.json`:

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

## Testing the Deployment

### 1. Test Token Wrapping

```javascript
// Wrap stAVAX → SY
const stAVAX = await ethers.getContractAt("MockERC20", mockStAVAXAddress);
const syWrapper = await ethers.getContractAt("StandardizedTokenWrapper", syWrapperAddress);

// Approve spending
await stAVAX.approve(syWrapper.address, ethers.utils.parseEther("100"));

// Wrap tokens
await syWrapper.wrap([ethers.utils.parseEther("100")]);
```

### 2. Test Yield Tokenization

```javascript
// Split SY → PT + YT
const yieldTokenization = await ethers.getContractAt("GenericYieldTokenization", yieldTokenizationAddress);

// Approve SY spending
await syWrapper.approve(yieldTokenization.address, ethers.utils.parseEther("100"));

// Split tokens
await yieldTokenization.split(ethers.utils.parseEther("100"), maturityTimestamp);
```

### 3. Test AMM Trading

```javascript
// Add liquidity to PT AMM
const ptAmm = await ethers.getContractAt("SimpleAMM", ptAmmAddress);

// Approve tokens
await ptToken.approve(ptAmm.address, ethers.utils.parseEther("100"));
await usdce.approve(ptAmm.address, ethers.utils.parseEther("1000"));

// Add liquidity
await ptAmm.addLiquidity(ethers.utils.parseEther("100"), ethers.utils.parseEther("1000"));
```

## Verification (Optional)

To verify contracts on Avalanche Explorer:

1. Get your API key from [Snowtrace](https://snowtrace.io/)
2. Add it to `hardhat.config.js`
3. Run verification:

```bash
npx hardhat verify --network avalanche_fuji CONTRACT_ADDRESS [CONSTRUCTOR_ARGS]
```

## Troubleshooting

### Common Issues

1. **Insufficient Gas**: Increase gas limit in hardhat config
2. **Contract Verification Failed**: Check constructor arguments match deployment
3. **Transaction Failed**: Check network RPC endpoint and gas price

### Gas Optimization

- Current gas price: 25 gwei
- Estimated total deployment cost: ~0.1-0.2 AVAX

## Next Steps

After successful deployment:

1. **Add Liquidity**: Fund AMMs with initial liquidity
2. **Test Integration**: Verify all contracts work together
3. **Frontend Integration**: Update frontend with new contract addresses
4. **User Testing**: Test the complete user flow

## Security Notes

- **Never share your private key**
- **Test thoroughly on testnet before mainnet**
- **Review all contract interactions**
- **Monitor for any unexpected behavior**

## Support

If you encounter issues:

1. Check the deployment logs for error messages
2. Verify your private key and network configuration
3. Ensure you have sufficient testnet AVAX
4. Check contract compilation for any errors 