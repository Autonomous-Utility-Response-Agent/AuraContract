const hre = require("hardhat");

async function main() {
  console.log("🚀 Deploying contracts to Sepolia...\n");

  // Deploy Mock USDC
  const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
  const usdc = await MockUSDC.deploy();
  await usdc.waitForDeployment();
  const usdcAddress = await usdc.getAddress();
  console.log("✅ MockUSDC deployed to:", usdcAddress);

  // Deploy AuraBounty
  const AuraBounty = await hre.ethers.getContractFactory("AuraBounty");
  const auraBounty = await AuraBounty.deploy(usdcAddress);
  await auraBounty.waitForDeployment();
  const bountyAddress = await auraBounty.getAddress();
  console.log("✅ AuraBounty deployed to:", bountyAddress);

  console.log("\n📝 Add these to your .env file:");
  console.log(`USDC_ADDRESS=${usdcAddress}`);
  console.log(`CONTRACT_ADDRESS=${bountyAddress}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
