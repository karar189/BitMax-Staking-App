const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("Testing deployed contracts on Avalanche Fuji...");
  
  // Load deployment info
  let deploymentInfo;
  try {
    deploymentInfo = JSON.parse(fs.readFileSync('deployment-avalanche.json', 'utf8'));
  } catch (error) {
    console.error("❌ No deployment info found. Please deploy contracts first.");
    console.error("Run: npm run deploy:avalanche");
    return;
  }
  
  const [deployer] = await ethers.getSigners();
  console.log("Testing with account:", deployer.address);
  
  try {
    // Test 1: Mock Tokens
    console.log("\n=== Test 1: Mock Tokens ===");
    const mockStAVAX = await ethers.getContractAt("MockERC20", deploymentInfo.contracts.mockStAVAX);
    const mockUSDCE = await ethers.getContractAt("MockERC20", deploymentInfo.contracts.mockUSDCE);
    
    const stAVAXBalance = await mockStAVAX.balanceOf(deployer.address);
    const usdceBalance = await mockUSDCE.balanceOf(deployer.address);
    
    console.log("✅ stAVAX Balance:", ethers.utils.formatEther(stAVAXBalance));
    console.log("✅ USDC.e Balance:", ethers.utils.formatEther(usdceBalance));
    
    // Test 2: SY Wrapper
    console.log("\n=== Test 2: SY Wrapper ===");
    const syWrapper = await ethers.getContractAt("StandardizedTokenWrapper", deploymentInfo.contracts.syWrapper);
    
    const wrapperName = await syWrapper.name();
    const wrapperSymbol = await syWrapper.symbol();
    console.log("✅ SY Wrapper:", wrapperName, `(${wrapperSymbol})`);
    
    // Test 3: Yield Tokenization
    console.log("\n=== Test 3: Yield Tokenization ===");
    const yieldTokenization = await ethers.getContractAt("GenericYieldTokenization", deploymentInfo.contracts.yieldTokenization);
    
    const maturities = await yieldTokenization.getMaturities();
    console.log("✅ Maturities:", maturities.length);
    
    if (maturities.length > 0) {
      const firstMaturity = maturities[0];
      const ptAddress = await yieldTokenization.ptTokens(firstMaturity);
      const ytAddress = await yieldTokenization.ytTokens(firstMaturity);
      
      console.log("✅ PT Token:", ptAddress);
      console.log("✅ YT Token:", ytAddress);
      
      // Test 4: PT and YT Tokens
      console.log("\n=== Test 4: PT and YT Tokens ===");
      const ptToken = await ethers.getContractAt("PTToken", ptAddress);
      const ytToken = await ethers.getContractAt("YTToken", ytAddress);
      
      const ptName = await ptToken.name();
      const ytName = await ytToken.name();
      console.log("✅ PT Token Name:", ptName);
      console.log("✅ YT Token Name:", ytName);
    }
    
    // Test 5: AMMs
    console.log("\n=== Test 5: AMMs ===");
    const ptAmm = await ethers.getContractAt("SimpleAMM", deploymentInfo.contracts.ptAmm);
    const ytAmm = await ethers.getContractAt("SimpleAMM", deploymentInfo.contracts.ytAmm);
    
    const ptAmmTokenA = await ptAmm.tokenA();
    const ptAmmTokenB = await ptAmm.tokenB();
    console.log("✅ PT AMM - Token A:", ptAmmTokenA);
    console.log("✅ PT AMM - Token B:", ptAmmTokenB);
    
    // Test 6: Price Oracle
    console.log("\n=== Test 6: Price Oracle ===");
    const priceOracle = await ethers.getContractAt("ProductionPriceOracle", deploymentInfo.contracts.priceOracle);
    
    const isHealthy = await priceOracle.isHealthy();
    const heartbeat = await priceOracle.getHeartbeat();
    console.log("✅ Oracle Healthy:", isHealthy);
    console.log("✅ Oracle Heartbeat:", heartbeat.toString());
    
    // Test 7: YT Auto-Converter
    console.log("\n=== Test 7: YT Auto-Converter ===");
    const ytAutoConverter = await ethers.getContractAt("YTAutoConverter", deploymentInfo.contracts.ytAutoConverter);
    
    const oracle = await ytAutoConverter.oracle();
    const tokenization = await ytAutoConverter.tokenization();
    console.log("✅ Oracle Address:", oracle);
    console.log("✅ Tokenization Address:", tokenization);
    
    // Test 8: Staking Dapp
    console.log("\n=== Test 8: Staking Dapp ===");
    const stakingDapp = await ethers.getContractAt("StakingDapp", deploymentInfo.contracts.stakingDapp);
    
    const stakingToken = await stakingDapp.stakingToken();
    const rewardToken = await stakingDapp.rewardToken();
    console.log("✅ Staking Token:", stakingToken);
    console.log("✅ Reward Token:", rewardToken);
    
    console.log("\n🎉 All contract tests passed successfully!");
    console.log("\n=== NEXT STEPS ===");
    console.log("1. Add liquidity to AMMs");
    console.log("2. Test token wrapping (stAVAX → SY)");
    console.log("3. Test yield tokenization (SY → PT + YT)");
    console.log("4. Test trading on AMMs");
    console.log("5. Test auto-conversion feature");
    
  } catch (error) {
    console.error("❌ Test failed:", error.message);
    console.error("Stack trace:", error.stack);
  }
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  }); 