const fs = require("fs");
const path = require("path");
const glob = require("glob");

// List every contract for which you want an ABI exported
const CONTRACTS = [
  "MockERC20",
  "StandardizedTokenWrapper",
  "GenericYieldTokenization",
  "PTToken",
  "YTToken",
  "SimpleAMM",
  "ProductionPriceOracle",
  "YTAutoConverter",
  "StakingDapp"
];

// Output folder
const OUT_DIR = path.join(__dirname, "../abis");
if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR);

function findArtifact(contract) {
  const matches = glob.sync(
    path.join(__dirname, `../artifacts/contracts/**/${contract}.json`)
  );
  if (!matches.length) throw new Error(`Artifact for ${contract} not found`);
  return matches[0];
}

CONTRACTS.forEach((c) => {
  try {
    const artifactPath = findArtifact(c);
    const { abi } = JSON.parse(fs.readFileSync(artifactPath, "utf8"));
    fs.writeFileSync(
      path.join(OUT_DIR, `${c}.json`),
      JSON.stringify(abi, null, 2)
    );
    console.log(`✓ Exported ABI for ${c}`);
  } catch (e) {
    console.error(`✗ Failed to export ABI for ${c}:`, e.message);
  }
});