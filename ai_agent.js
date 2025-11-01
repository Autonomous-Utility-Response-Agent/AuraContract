const { ethers } = require("ethers");
const axios = require("axios");
require("dotenv").config();

const ABI = require("./artifacts/contracts/AuraBounty.sol/AuraBounty.json").abi;
const USDC_ABI = require("./artifacts/contracts/MockUSDC.sol/MockUSDC.json").abi;

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, ABI, wallet);
const usdcContract = new ethers.Contract(process.env.USDC_ADDRESS, USDC_ABI, wallet);

async function checkGrid() {
  try {
    console.log("\n🔍 Checking grid status...");
    
    const response = await axios.get(
      "https://api.electricitymap.org/v3/carbon-intensity/latest?zone=US-CAL-CISO",
      { headers: { "auth-token": process.env.ELECTRICITYMAPS_TOKEN } }
    );
    
    const carbon = response.data.carbonIntensity;
    console.log(`📊 Carbon Intensity: ${carbon} gCO2eq/kWh`);
    
    if (carbon > 400) {
      console.log("⚠️  HIGH CARBON DETECTED — Creating bounty!");
      
      const rewardPerKwh = ethers.parseUnits("1", 6); // 1 USDC per kWh
      const totalBudget = ethers.parseUnits("100", 6); // 100 USDC
      const deadline = Math.floor(Date.now() / 1000) + 1800; // 30 min
      
      // Approve USDC spending
      console.log("💰 Approving USDC...");
      const approveTx = await usdcContract.approve(process.env.CONTRACT_ADDRESS, totalBudget);
      await approveTx.wait();
      
      // Create bounty
      console.log("🚀 Creating bounty...");
      const tx = await contract.createBounty(rewardPerKwh, totalBudget, deadline);
      const receipt = await tx.wait();
      
      console.log("✅ Bounty created!");
      console.log(`   TX: ${receipt.hash}`);
      console.log(`   View: https://sepolia.etherscan.io/tx/${receipt.hash}`);
    } else {
      console.log("✅ Grid stable — no action needed");
    }
  } catch (err) {
    console.error("❌ Error:", err.message);
  }
}

async function main() {
  console.log("🤖 Aura AI Agent Started");
  console.log(`📍 Monitoring: US-CAL-CISO`);
  console.log(`🔗 Contract: ${process.env.CONTRACT_ADDRESS}`);
  
  // Check immediately
  await checkGrid();
  
  // Then check every 60 seconds
  setInterval(checkGrid, 60000);
}

main();
