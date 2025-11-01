
# 🧭 TODO.md — Aura AI Agent Implementation Plan  
### Repository: Autonomous-Utility-Response-Agent/AuraContract  
### Team: FantasticFour  

---

## 🎯 Goal — What We Want to Achieve

We aim to build the **Aura Autonomous Utility Response Agent**, a Node.js-based AI service that:  
- Monitors real-time **electric grid stress** using the **Electricity Maps API**.  
- Detects when carbon intensity or electricity price spikes.  
- Automatically **creates “Demand Response Bounties”** on the **AuraBounty.sol** smart contract.  
- Allows **IoT devices** (like ESP32 smart lamps) to respond by reducing consumption.  
- Verifies these actions via oracles (mocked for hackathon) and rewards participants in **mock USDC** tokens.  

Outcome: a **fully autonomous AI–IoT–Blockchain loop** that shows how decentralized agents can stabilize the grid and make sustainability profitable.

---

# 👨‍💻 HUMAN DEVELOPER PATH

## 1️⃣ Register & Obtain API Keys

### ⚡ Electricity Maps API
- **Purpose:** Source of real-time carbon intensity & energy price data.  
- **Register:** [https://api.electricitymap.org/](https://api.electricitymap.org/)  
- **Steps:**
  1. Create a free developer account.  
  2. Obtain an **API Token**.  
  3. Store it in `.env`:  
     ```bash
     ELECTRICITYMAPS_TOKEN=your_api_token_here
     ```
  4. Test API connection:  
     ```bash
     curl -H "auth-token: $ELECTRICITYMAPS_TOKEN"      https://api.electricitymap.org/v3/carbon-intensity/latest?zone=US-CAL-CISO
     ```

### 🔗 Ethereum RPC Provider (Alchemy or Infura)
- **Purpose:** Enable smart contract transactions from the AI agent.  
- **Register at:**  
  - [https://alchemy.com/](https://alchemy.com/) (recommended)  
  - or [https://infura.io/](https://infura.io/)  
- **Steps:**
  1. Create a project on **Sepolia Testnet**.  
  2. Copy the RPC endpoint:  
     ```bash
     RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_key
     ```

### 💼 Wallet & Private Key
- **Purpose:** The AI Agent will use this wallet to sign transactions.  
- **Tool:** [MetaMask](https://metamask.io/)  
- **Steps:**
  1. Create/import a wallet in MetaMask.  
  2. Switch to **Sepolia Test Network**.  
  3. Obtain test ETH: [https://sepoliafaucet.com/](https://sepoliafaucet.com/).  
  4. Export private key and add it to `.env`:  
     ```bash
     PRIVATE_KEY=your_wallet_private_key
     ```

### 💰 Mock USDC Token
- **Purpose:** Used by AuraBounty.sol to issue payouts.  
- **Steps:**
  1. Deploy or obtain mock ERC-20 (OpenZeppelin USDC).  
  2. Add token address to `.env`:  
     ```bash
     USDC_ADDRESS=0xYourMockTokenAddress
     ```

---

## 2️⃣ Environment Setup

### Install Node.js & Hardhat
```bash
npm install -g hardhat
npx hardhat --version
```
Should return a valid Hardhat version.

### Install Dependencies for AI Agent
```bash
npm install axios ethers dotenv
```

### Verify Blockchain Access
```bash
npx hardhat console --network sepolia
> ethers.provider.getBlockNumber()
```
If you get a number — your RPC and wallet setup are correct.

---

## 3️⃣ Deploy Smart Contract
1. Compile and deploy `AuraBounty.sol` on Sepolia:
   ```bash
   npx hardhat compile
   npx hardhat run scripts/deploy.js --network sepolia
   ```
2. Copy deployed contract address into `.env`:
   ```bash
   CONTRACT_ADDRESS=0xDeployedAuraBountyAddress
   ```

---

## 4️⃣ Testing and Verification (Human)

| Test | Description | Expected Output |
|------|--------------|-----------------|
| Electricity Maps API call | Verify API key works | Returns carbon intensity JSON |
| Hardhat compile | Ensure contract builds | ✅ Compilation successful |
| Deploy script | Ensure deployment success | Contract address + tx hash |
| RPC connectivity | Test ethers provider | Valid block number |
| AI trigger test | Run ai_agent.js manually | Creates a bounty transaction |
| IoT mock claim | Send test claim | Emits `RewardClaimed` event |

---

# 🤖 AI AGENT PATH

## 🧠 Responsibilities
The AI Agent performs continuous, autonomous monitoring and blockchain interaction.

| Step | Task | Output |
|------|------|---------|
| 1 | Monitor real-time grid stress via API | Carbon intensity + price |
| 2 | Evaluate thresholds (AI logic) | “Grid stable” / “Grid stressed” |
| 3 | Trigger `createBounty()` when stressed | Blockchain tx hash |
| 4 | Log and store event | Console + local JSON |
| 5 | (Future) Verify IoT claims | Oracle call + payout |

---

## 🧩 Files to Develop

```
AuraAI/
├── ai_agent.js
├── .env
└── README.md
```

---

## 🔧 AI Agent Development Steps

### 1️⃣ Initialize Environment
```js
import dotenv from "dotenv";
dotenv.config();
```

### 2️⃣ Connect to Blockchain
```js
import { ethers } from "ethers";
import axios from "axios";
import abi from "./AuraBounty.json" assert { type: "json" };

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, abi, wallet);
```

### 3️⃣ Fetch Grid Data
```js
const response = await axios.get(
  "https://api.electricitymap.org/v3/carbon-intensity/latest?zone=US-CAL-CISO",
  { headers: { "auth-token": process.env.ELECTRICITYMAPS_TOKEN } }
);
const carbon = response.data.carbonIntensity;
const price = response.data.price;
```

### 4️⃣ AI Logic
```js
if (carbon > 400 || price > 120) {
  console.log("⚠️ Grid stress detected — creating bounty!");
  const rewardPerKwh = 1;
  const totalBudget = 100;
  const deadline = Math.floor(Date.now() / 1000) + 1800;
  const tx = await contract.createBounty(rewardPerKwh, totalBudget, deadline);
  await tx.wait();
  console.log("✅ Bounty created:", tx.hash);
} else {
  console.log("✅ Grid stable.");
}
```

### 5️⃣ Scheduler
```js
setInterval(async () => {
  try {
    await checkGrid();
  } catch (err) {
    console.error("Error:", err.message);
  }
}, 60000); // Check every 60 seconds
```

---

# 🧪 TESTS TO DEVELOP

| Test ID | Type | Description | Method | Expected Result |
|----------|------|-------------|---------|-----------------|
| T1 | API | Test Electricity Maps connection | `curl` or axios | Returns valid JSON |
| T2 | Blockchain | Deploy AuraBounty contract | Hardhat deploy | Valid contract address |
| T3 | AI | Trigger createBounty manually | Node script | Transaction confirmed |
| T4 | IoT | Mock claimReward | REST call / Python test | RewardClaimed event |
| T5 | Error Handling | Missing API token | Simulate empty key | Graceful error message |
| T6 | Stress Logic | Simulate high carbon | Mock response | Bounty triggered |
| T7 | Scheduler | Continuous loop | Run for 5 min | Logs at 1-min intervals |
| T8 | Integration | Full chain (AI → Contract → IoT) | End-to-end test | Successful bounty + claim |

---

# 🧩 FINAL CHECKLIST

| Task | Responsible | Status |
|------|--------------|---------|
| Register Electricity Maps API | Human | ☐ |
| Setup RPC Provider | Human | ☐ |
| Configure Wallet and .env | Human | ☐ |
| Deploy AuraBounty.sol | Human | ☐ |
| Install AI Agent dependencies | AI | ☐ |
| Implement Monitoring Logic | AI | ☐ |
| Run Manual Tests | Human | ☐ |
| Observe Bounty Creation | Human + AI | ☐ |
| Develop Claim Verification | Human (future) | ☐ |

---

## 🚀 Future Enhancements
- Add real-time dashboard (Next.js / Streamlit).  
- Integrate Chainlink Functions oracle.  
- Implement AI-based prediction of grid stress.  
- Enable multi-region bounty creation.  
- Gamify energy savings with NFT achievements.

---

**Document Version:** 1.1  
**Authors:** Team FantasticFour — Assets on Chain Hackathon, San Francisco 2025  
© 2025 — Aura Autonomous Utility Response Agent Project
