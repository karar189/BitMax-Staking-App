const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts to Avalanche Fuji with account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()));
  
  // Step 1: Deploy Mock yield-bearing tokens for Avalanche
  console.log("\n=== Step 1: Deploying Mock Yield-Bearing Tokens ===");
  
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  
  // Mock stAVAX (staked AVAX)
  const mockStAVAX = await MockERC20.deploy("Mock Staked AVAX", "stAVAX", 800); // 8% APY
  await mockStAVAX.deployed();
  console.log("Mock stAVAX deployed to:", mockStAVAX.address);
  
  // Mock USDC.e (USDC on Avalanche)
  const mockUSDCE = await MockERC20.deploy("Mock USDC.e", "USDC.e", 500); // 5% APY
  await mockUSDCE.deployed();
  console.log("Mock USDC.e deployed to:", mockUSDCE.address);
  
  // Step 2: Deploy StandardizedTokenWrapper
  console.log("\n=== Step 2: Deploying StandardizedTokenWrapper ===");
  
  const StandardizedTokenWrapper = await ethers.getContractFactory("StandardizedTokenWrapper");
  const syWrapper = await StandardizedTokenWrapper.deploy("SY stAVAX", "SY-stAVAX", 800);
  await syWrapper.deployed();
  console.log("SY Wrapper deployed to:", syWrapper.address);
  
  // Configure the wrapper to accept stAVAX
  await syWrapper.configureToken(0, mockStAVAX.address, 10000, true); // 100% ratio
  console.log("SY Wrapper configured for stAVAX");
  
  // Step 3: Deploy GenericYieldTokenization
  console.log("\n=== Step 3: Deploying GenericYieldTokenization ===");
  
  const GenericYieldTokenization = await ethers.getContractFactory("GenericYieldTokenization");
  const yieldTokenization = await GenericYieldTokenization.deploy(
    syWrapper.address,
    "stAVAX Yield",  // base name for PT and YT tokens
    "stAVAX"         // base symbol for PT and YT tokens
  );
  await yieldTokenization.deployed();
  console.log("GenericYieldTokenization deployed to:", yieldTokenization.address);
  
  // Step 4: Create Maturities (this will auto-deploy PT + YT tokens)
  console.log("\n=== Step 4: Creating Maturities ===");
  
  // Create 3 month maturity
  const threeMonthMaturity = Math.floor(Date.now() / 1000) + (90 * 24 * 60 * 60); // 90 days from now
  await yieldTokenization.createMaturity(threeMonthMaturity);
  console.log("3-month maturity created");
  
  // Create 6 month maturity
  const sixMonthMaturity = Math.floor(Date.now() / 1000) + (180 * 24 * 60 * 60); // 180 days from now
  await yieldTokenization.createMaturity(sixMonthMaturity);
  console.log("6-month maturity created");
  
  // Get the first maturity's PT and YT tokens
  const maturities = await yieldTokenization.getMaturities();
  const firstMaturity = maturities[0];
  const ptAddress = await yieldTokenization.ptTokens(firstMaturity);
  const ytAddress = await yieldTokenization.ytTokens(firstMaturity);
  
  console.log("PT Token (3M):", ptAddress);
  console.log("YT Token (3M):", ytAddress);
  
  // Step 5: Deploy SimpleAMM for trading
  console.log("\n=== Step 5: Deploying SimpleAMM ===");
  
  const SimpleAMM = await ethers.getContractFactory("SimpleAMM");
  
  // AMM for PT ↔ USDC.e trading
  const ptAmm = await SimpleAMM.deploy(ptAddress, mockUSDCE.address);
  await ptAmm.deployed();
  console.log("PT AMM deployed to:", ptAmm.address);
  
  // AMM for YT ↔ USDC.e trading
  const ytAmm = await SimpleAMM.deploy(ytAddress, mockUSDCE.address);
  await ytAmm.deployed();
  console.log("YT AMM deployed to:", ytAmm.address);
  
  // Step 6: Deploy ProductionPriceOracle
  console.log("\n=== Step 6: Deploying ProductionPriceOracle ===");
  
  const ProductionPriceOracle = await ethers.getContractFactory("ProductionPriceOracle");
  const priceOracle = await ProductionPriceOracle.deploy();
  await priceOracle.deployed();
  console.log("ProductionPriceOracle deployed to:", priceOracle.address);
  
  // Step 7: Deploy YTAutoConverter (optional but cool feature)
  console.log("\n=== Step 7: Deploying YTAutoConverter ===");
  
  const YTAutoConverter = await ethers.getContractFactory("YTAutoConverter");
  const ytAutoConverter = await YTAutoConverter.deploy(
    yieldTokenization.address,
    priceOracle.address,
    5000 // 50% threshold for auto-conversion
  );
  await ytAutoConverter.deployed();
  console.log("YTAutoConverter deployed to:", ytAutoConverter.address);
  
  // Step 8: Deploy StakingDapp (optional)
  console.log("\n=== Step 8: Deploying StakingDapp ===");
  
  const StakingDapp = await ethers.getContractFactory("StakingDapp");
  const stakingDapp = await StakingDapp.deploy(mockStAVAX.address, mockUSDCE.address);
  await stakingDapp.deployed();
  console.log("StakingDapp deployed to:", stakingDapp.address);
  
  // Step 9: Setup initial liquidity and permissions
  console.log("\n=== Step 9: Setting up Initial Configuration ===");
  
  // Mint some initial tokens for demo
  await mockStAVAX.mint(deployer.address, ethers.utils.parseEther("10000")); // 10k stAVAX
  await mockUSDCE.mint(deployer.address, ethers.utils.parseEther("50000")); // 50k USDC.e
  
  // Transfer ownership of key contracts to deployer for management
  await syWrapper.transferOwnership(deployer.address);
  await yieldTokenization.transferOwnership(deployer.address);
  
  // Print deployment summary
  console.log("\n=== DEPLOYMENT SUMMARY ===");
  console.log("Network: Avalanche Fuji Testnet");
  console.log("Deployer:", deployer.address);
  console.log("\nMock Tokens:");
  console.log("  stAVAX:", mockStAVAX.address);
  console.log("  USDC.e:", mockUSDCE.address);
  console.log("\nCore Contracts:");
  console.log("  SY Wrapper:", syWrapper.address);
  console.log("  Yield Tokenization:", yieldTokenization.address);
  console.log("  PT Token (3M):", ptAddress);
  console.log("  YT Token (3M):", ytAddress);
  console.log("\nAMM Contracts:");
  console.log("  PT AMM:", ptAmm.address);
  console.log("  YT AMM:", ytAmm.address);
  console.log("\nInfrastructure:");
  console.log("  Price Oracle:", priceOracle.address);
  console.log("  YT Auto-Converter:", ytAutoConverter.address);
  console.log("  Staking Dapp:", stakingDapp.address);
  
  console.log("\n=== NEXT STEPS ===");
  console.log("1. Add liquidity to AMMs");
  console.log("2. Test token wrapping (stAVAX → SY)");
  console.log("3. Test yield tokenization (SY → PT + YT)");
  console.log("4. Test trading on AMMs");
  console.log("5. Test auto-conversion feature");
  
  // Save deployment addresses to a file for frontend integration
  const deploymentInfo = {
    network: "avalanche_fuji",
    deployer: deployer.address,
    contracts: {
      mockStAVAX: mockStAVAX.address,
      mockUSDCE: mockUSDCE.address,
      syWrapper: syWrapper.address,
      yieldTokenization: yieldTokenization.address,
      ptToken: ptAddress,
      ytToken: ytAddress,
      ptAmm: ptAmm.address,
      ytAmm: ytAmm.address,
      priceOracle: priceOracle.address,
      ytAutoConverter: ytAutoConverter.address,
      stakingDapp: stakingDapp.address
    },
    deploymentTime: new Date().toISOString()
  };
  
  const fs = require('fs');
  fs.writeFileSync('deployment-avalanche.json', JSON.stringify(deploymentInfo, null, 2));
  console.log("\nDeployment info saved to: deployment-avalanche.json");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  }); 