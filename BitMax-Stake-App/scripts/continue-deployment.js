const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Continuing deployment to Avalanche Fuji with account:", deployer.address);
  console.log("Account balance:", ethers.utils.formatEther(await deployer.getBalance()));
  
  // Use the already deployed contract addresses
  const mockStAVAXAddress = "0x9B73ded25dC5eb82b07FFf0EB6dB9388B944fb22";
  const mockUSDCEAddress = "0x3dCFDeDefD79b62fB736f0e1f1c214aF36474C0E";
  const syWrapperAddress = "0xc94a4fA575723aa0c8f4079ee0a8dEdAd05510c6";
  const yieldTokenizationAddress = "0x5a9Ec7DD090Df8E18CD15C052C74e0C9AfD4aC7c";
  
  console.log("Using deployed contracts:");
  console.log("Mock stAVAX:", mockStAVAXAddress);
  console.log("Mock USDC.e:", mockUSDCEAddress);
  console.log("SY Wrapper:", syWrapperAddress);
  console.log("Yield Tokenization:", yieldTokenizationAddress);
  
  // Step 4: Create Maturities (this will auto-deploy PT + YT tokens)
  console.log("\n=== Step 4: Creating Maturities ===");
  
  const yieldTokenization = await ethers.getContractAt("GenericYieldTokenization", yieldTokenizationAddress);
  
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
  const ptAmm = await SimpleAMM.deploy(ptAddress, mockUSDCEAddress);
  await ptAmm.deployed();
  console.log("PT AMM deployed to:", ptAmm.address);
  
  // AMM for YT ↔ USDC.e trading
  const ytAmm = await SimpleAMM.deploy(ytAddress, mockUSDCEAddress);
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
    priceOracle.address,        // _oracle
    yieldTokenization.address,  // _tokenization
    mockStAVAXAddress,          // _referenceToken (stAVAX for price monitoring)
    ptAmm.address               // _amm (PT AMM for swapping)
  );
  await ytAutoConverter.deployed();
  console.log("YTAutoConverter deployed to:", ytAutoConverter.address);
  
  // Step 8: Deploy StakingDapp (optional)
  console.log("\n=== Step 8: Deploying StakingDapp ===");
  
  const StakingDapp = await ethers.getContractFactory("StakingDapp");
  const stakingDapp = await StakingDapp.deploy(mockStAVAXAddress, mockUSDCEAddress);
  await stakingDapp.deployed();
  console.log("StakingDapp deployed to:", stakingDapp.address);
  
  // Step 9: Setup initial liquidity and permissions
  console.log("\n=== Step 9: Setting up Initial Configuration ===");
  
  // Mint some initial tokens for demo
  const mockStAVAX = await ethers.getContractAt("MockERC20", mockStAVAXAddress);
  const mockUSDCE = await ethers.getContractAt("MockERC20", mockUSDCEAddress);
  
  await mockStAVAX.mint(deployer.address, ethers.utils.parseEther("10000")); // 10k stAVAX
  await mockUSDCE.mint(deployer.address, ethers.utils.parseEther("50000")); // 50k USDC.e
  
  // Transfer ownership of key contracts to deployer for management
  await yieldTokenization.transferOwnership(deployer.address);
  
  // Print deployment summary
  console.log("\n=== DEPLOYMENT SUMMARY ===");
  console.log("Network: Avalanche Fuji Testnet");
  console.log("Deployer:", deployer.address);
  console.log("\nMock Tokens:");
  console.log("  stAVAX:", mockStAVAXAddress);
  console.log("  USDC.e:", mockUSDCEAddress);
  console.log("\nCore Contracts:");
  console.log("  SY Wrapper:", syWrapperAddress);
  console.log("  Yield Tokenization:", yieldTokenizationAddress);
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
      mockStAVAX: mockStAVAXAddress,
      mockUSDCE: mockUSDCEAddress,
      syWrapper: syWrapperAddress,
      yieldTokenization: yieldTokenizationAddress,
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