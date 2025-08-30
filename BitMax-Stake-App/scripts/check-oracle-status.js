const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("🔍 Checking Oracle Status on Avalanche Fuji...");
  
  // Load deployment info
  let deploymentInfo;
  try {
    deploymentInfo = JSON.parse(fs.readFileSync('deployment-avalanche.json', 'utf8'));
  } catch (error) {
    console.error("❌ No deployment info found. Please deploy contracts first.");
    return;
  }
  
  const [deployer] = await ethers.getSigners();
  console.log("Checking with account:", deployer.address);
  
  try {
    // Get oracle contract
    const priceOracle = await ethers.getContractAt("ProductionPriceOracle", deploymentInfo.contracts.priceOracle);
    console.log("Oracle Address:", deploymentInfo.contracts.priceOracle);
    
    // Check oracle health
    const isHealthy = await priceOracle.isHealthy();
    const heartbeat = await priceOracle.getHeartbeat();
    console.log("\n=== Oracle Health ===");
    console.log("✅ Healthy:", isHealthy);
    console.log("✅ Heartbeat:", heartbeat.toString(), "seconds");
    
    // Check which tokens have prices set
    console.log("\n=== Token Price Status ===");
    
    const tokensToCheck = [
      { name: "Mock stAVAX", address: deploymentInfo.contracts.mockStAVAX },
      { name: "Mock USDC.e", address: deploymentInfo.contracts.mockUSDCE },
      { name: "PT Token (3M)", address: deploymentInfo.contracts.ptToken },
      { name: "YT Token (3M)", address: deploymentInfo.contracts.ytToken }
    ];
    
    for (const token of tokensToCheck) {
      try {
        const price = await priceOracle.getPrice(token.address);
        const threshold = await priceOracle.getThreshold(token.address);
        const thresholdReached = await priceOracle.thresholdReached(token.address);
        
        console.log(`\n${token.name}:`);
        console.log(`  Address: ${token.address}`);
        console.log(`  Price: $${ethers.utils.formatUnits(price, 8)}`);
        console.log(`  Threshold: $${ethers.utils.formatUnits(threshold, 8)}`);
        console.log(`  Threshold Reached: ${thresholdReached}`);
        
        // Get price data details
        const priceData = await priceOracle.prices(token.address);
        if (priceData.price.gt(0)) {
          console.log(`  Last Updated: ${new Date(priceData.timestamp.toNumber() * 1000).toISOString()}`);
          console.log(`  Confidence: ${priceData.confidence / 100}%`);
          console.log(`  Updater: ${priceData.updater}`);
        }
      } catch (error) {
        console.log(`\n${token.name}:`);
        console.log(`  Address: ${token.address}`);
        console.log(`  ❌ No price set or error: ${error.message}`);
      }
    }
    
    // Check authorized price updaters
    console.log("\n=== Authorized Price Updaters ===");
    const deployerIsUpdater = await priceOracle.priceUpdaters(deployer.address);
    console.log(`Deployer (${deployer.address}): ${deployerIsUpdater ? '✅ Authorized' : '❌ Not Authorized'}`);
    
    // Check circuit breaker status
    const circuitBreakerActive = await priceOracle.circuitBreakerActive();
    console.log(`Circuit Breaker: ${circuitBreakerActive ? '🔴 ACTIVE' : '🟢 Inactive'}`);
    
    // Check if oracle is paused
    const isPaused = await priceOracle.paused();
    console.log(`Oracle Paused: ${isPaused ? '🔴 YES' : '🟢 NO'}`);
    
    console.log("\n=== Oracle Summary ===");
    console.log("Your oracle is currently monitoring these tokens:");
    console.log("1. Mock stAVAX - for auto-conversion thresholds");
    console.log("2. Mock USDC.e - base currency for pricing");
    console.log("3. PT Token (3M) - Principal Token price");
    console.log("4. YT Token (3M) - Yield Token price");
    
    console.log("\n=== How to Add Prices ===");
    console.log("To set prices for tokens, use:");
    console.log("await priceOracle.updatePrice(tokenAddress, priceIn8Decimals, confidenceLevel);");
    console.log("Example: await priceOracle.updatePrice(stAVAX, ethers.utils.parseUnits('45', 8), 8000);");
    
  } catch (error) {
    console.error("❌ Error checking oracle:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  }); 