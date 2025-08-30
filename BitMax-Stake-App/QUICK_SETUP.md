# Quick Setup for Avalanche Fuji Deployment

## 1. Get Testnet AVAX
- Visit: https://faucet.avax.network/
- Connect your wallet
- Request testnet AVAX (you'll get 2 AVAX)

## 2. Setup Your Private Key
```bash
# Edit secret.json with your private key
nano secret.json
```

Replace the placeholder with your actual private key:
```json
{
  "PrivateKey": "0x1234567890abcdef..."
}
```

## 3. Deploy All Contracts
```bash
npm run deploy:avalanche
```

## 4. What Gets Deployed
1. **Mock Tokens**: stAVAX (8% APY), USDC.e (5% APY)
2. **SY Wrapper**: Wraps stAVAX → SY tokens
3. **Yield Tokenization**: Splits SY → PT + YT (1:1)
4. **Maturities**: 3-month and 6-month PT/YT pairs
5. **AMMs**: Trading pairs for PT ↔ USDC.e and YT ↔ USDC.e
6. **Price Oracle**: Price feeds and threshold monitoring
7. **Auto-Converter**: Auto-converts YT → PT based on oracle signals
8. **Staking Dapp**: LP staking and rewards

## 5. Test the System
```javascript
// After deployment, test:
// 1. Wrap stAVAX → SY
// 2. Split SY → PT + YT
// 3. Trade PT/YT on AMMs
// 4. Test auto-conversion
```

## 6. Contract Addresses
All addresses will be saved to `deployment-avalanche.json`

## 7. Frontend Integration
Update your frontend with the new contract addresses from the deployment file.

## 8. Network Details
- **Network**: Avalanche Fuji Testnet
- **Chain ID**: 43113
- **RPC**: https://api.avax-test.network/ext/bc/C/rpc
- **Explorer**: https://testnet.snowtrace.io/

## Troubleshooting
- **Insufficient Gas**: Make sure you have >0.1 AVAX for deployment
- **Private Key**: Must be 64 characters (32 bytes) hex string
- **Network**: Ensure you're connected to Fuji testnet 