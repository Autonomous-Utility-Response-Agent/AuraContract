# 🧭 TODO.md — Aura AI Agent Implementation Plan  
### Repository: Autonomous-Utility-Response-Agent/AuraContract  
### Team: FantasticFour  

---

## 🎯 Goal — What We Want to Achieve

We aim to build the **Aura Autonomous Utility Response Agent**, a Node.js-based AI service that:  
- Monitors real-time **electric grid stress** using the **Electricity Maps API**.  
- Detects when carbon intensity or electricity price spikes.  
- Automatically **creates "Demand Response Bounties"** on the **AuraBounty.sol** smart contract.  
- Allows **IoT devices** (like ESP32 smart lamps) to respond by reducing consumption.  
- Verifies these actions via oracles (mocked for hackathon) and rewards participants in **mock USDC** tokens.  

Outcome: a **fully autonomous AI–IoT–Blockchain loop** that shows how decentralized agents can stabilize the grid and make sustainability profitable.

---

# 👨💻 HUMAN DEVELOPER PATH

## 1️⃣ Register & Obtain API Keys

### ⚡ Electricity Maps API ✅ DONE
- **Purpose:** Source of real-time carbon intensity & energy price data.  
- **Register:** [https://api.electricitymap.org/](https://api.electricitymap.org/)  
- **Status:** ✅ API token obtained: `pCLyt2braf6LlZALA4QH`
- **Stored in `.env`:** ✅

### 🔗 Ethereum RPC Provider (Alchemy) ✅ DONE
- **Purpose:** Enable smart contract transactions from the AI agent.  
- **Register at:** [https://alchemy.com/](https://alchemy.com/)
- **Status:** ✅ Project created on Sepolia Testnet
- **API Key:** `3rBF5WTjI22cU2WaA3R_B`
- **RPC URL:** `https://eth-sepolia.g.alchemy.com/v2/3rBF5WTjI22cU2WaA3R_B`
- **Stored in `.env`:** ✅

### 💼 Wallet & Private Key ✅ DONE
- **Purpose:** The AI Agent will use this wallet to sign transactions.  
- **Tool:** Exodus wallet (instead of MetaMask)
- **Status:** ✅ Wallet configured
- **Address:** `0xd5af98477D7227f8bbB340823EeB322A5C7c67A7`
- **Balance:** 0.1 Sepolia ETH
- **Private key stored in `.env`:** ✅

### 💰 Mock USDC Token ✅ DONE
- **Purpose:** Used by AuraBounty.sol to issue payouts.  
- **Status:** ✅ Deployed to Sepolia
- **Address:** `0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce`
- **View on Etherscan:** [MockUSDC](https://sepolia.etherscan.io/address/0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce)

---

## 2️⃣ Environment Setup ✅ DONE

### Install Node.js & Hardhat ✅
```bash
npm install -g hardhat
npx hardhat --version
```
**Status:** ✅ Hardhat 2.22.0 installed

### Install Dependencies for AI Agent ✅
```bash
npm install axios ethers dotenv
```
**Status:** ✅ All dependencies installed

### Verify Blockchain Access ✅
```bash
npx hardhat console --network sepolia
> ethers.provider.getBlockNumber()
```
**Status:** ✅ RPC connection verified

---

## 3️⃣ Deploy Smart Contract ✅ DONE

**Status:** ✅ Contracts deployed to Sepolia

1. **MockUSDC:** `0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce`
2. **AuraBounty:** `0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1`

**Deployment command:**
```bash
npx hardhat compile
npx hardhat run scripts/deploy.js --network sepolia
```

**View on Etherscan:**
- [MockUSDC Contract](https://sepolia.etherscan.io/address/0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce)
- [AuraBounty Contract](https://sepolia.etherscan.io/address/0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1)

---

## 4️⃣ Testing and Verification

| Test | Description | Status | Expected Output |
|------|--------------|--------|-----------------|
| Electricity Maps API call | Verify API key works | ✅ DONE | Returns carbon intensity JSON |
| Hardhat compile | Ensure contract builds | ✅ DONE | ✅ Compilation successful |
| Deploy script | Ensure deployment success | ✅ DONE | Contract address + tx hash |
| RPC connectivity | Test ethers provider | ✅ DONE | Valid block number |
| AI trigger test | Run ai_agent.js manually | 🔄 READY | Creates a bounty transaction |
| IoT mock claim | Send test claim | 🔄 READY | Emits `RewardClaimed` event |

---

# 🤖 AI AGENT PATH

## 🧠 Responsibilities
The AI Agent performs continuous, autonomous monitoring and blockchain interaction.

| Step | Task | Status | Output |
|------|------|--------|---------|
| 1 | Monitor real-time grid stress via API | ✅ DONE | Carbon intensity + price |
| 2 | Evaluate thresholds (AI logic) | ✅ DONE | "Grid stable" / "Grid stressed" |
| 3 | Trigger `createBounty()` when stressed | ✅ DONE | Blockchain tx hash |
| 4 | Log and store event | ✅ DONE | Console + local JSON |
| 5 | (Future) Verify IoT claims | 🔄 TODO | Oracle call + payout |

---

## 🧩 Files Developed

```
AuraContract/
├── ai_agent.js              ✅ DONE
├── contracts/
│   ├── AuraBounty.sol       ✅ DONE
│   └── MockUSDC.sol         ✅ DONE
├── scripts/
│   └── deploy.js            ✅ DONE
├── hardhat.config.js        ✅ DONE
├── .env                     ✅ DONE
└── README.md                ✅ UPDATED
```

---

## 🔧 AI Agent Implementation ✅ DONE

### 1️⃣ Initialize Environment ✅
```js
require("dotenv").config();
```

### 2️⃣ Connect to Blockchain ✅
```js
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, abi, wallet);
```

### 3️⃣ Fetch Grid Data ✅
```js
const response = await axios.get(
  "https://api.electricitymap.org/v3/carbon-intensity/latest?zone=US-CAL-CISO",
  { headers: { "auth-token": process.env.ELECTRICITYMAPS_TOKEN } }
);
const carbon = response.data.carbonIntensity;
```

### 4️⃣ AI Logic ✅
```js
if (carbon > 400) {
  console.log("⚠️ Grid stress detected — creating bounty!");
  const rewardPerKwh = ethers.parseUnits("1", 6);
  const totalBudget = ethers.parseUnits("100", 6);
  const deadline = Math.floor(Date.now() / 1000) + 1800;
  
  await usdcContract.approve(CONTRACT_ADDRESS, totalBudget);
  const tx = await contract.createBounty(rewardPerKwh, totalBudget, deadline);
  await tx.wait();
  console.log("✅ Bounty created:", tx.hash);
}
```

### 5️⃣ Scheduler ✅
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

| Test ID | Type | Description | Method | Status | Expected Result |
|----------|------|-------------|---------|--------|-----------------|
| T1 | API | Test Electricity Maps connection | `curl` or axios | ✅ DONE | Returns valid JSON |
| T2 | Blockchain | Deploy AuraBounty contract | Hardhat deploy | ✅ DONE | Valid contract address |
| T3 | AI | Trigger createBounty manually | Node script | 🔄 READY | Transaction confirmed |
| T4 | IoT | Mock claimReward | REST call / Python test | 🔄 TODO | RewardClaimed event |
| T5 | Error Handling | Missing API token | Simulate empty key | 🔄 TODO | Graceful error message |
| T6 | Stress Logic | Simulate high carbon | Mock response | 🔄 TODO | Bounty triggered |
| T7 | Scheduler | Continuous loop | Run for 5 min | 🔄 READY | Logs at 1-min intervals |
| T8 | Integration | Full chain (AI → Contract → IoT) | End-to-end test | 🔄 TODO | Successful bounty + claim |

---

# 🧩 FINAL CHECKLIST

| Task | Responsible | Status |
|------|--------------|---------|
| Register Electricity Maps API | Human | ✅ DONE |
| Setup RPC Provider | Human | ✅ DONE |
| Configure Wallet and .env | Human | ✅ DONE (Exodus) |
| Deploy MockUSDC | Human | ✅ DONE |
| Deploy AuraBounty.sol | Human | ✅ DONE |
| Install AI Agent dependencies | AI | ✅ DONE |
| Implement Monitoring Logic | AI | ✅ DONE |
| Create ai_agent.js | AI | ✅ DONE |
| Run Manual Tests | Human | 🔄 READY |
| Observe Bounty Creation | Human + AI | 🔄 READY |
| Develop Claim Verification | Human (future) | 🔄 TODO |
| Build IoT Integration | Human (future) | 🔄 TODO |

---

## 🚀 Next Steps (Future Enhancements)

- [ ] Add real-time dashboard (Next.js / Streamlit)
- [ ] Integrate Chainlink Functions oracle for claim verification
- [ ] Implement AI-based prediction of grid stress
- [ ] Enable multi-region bounty creation
- [ ] Gamify energy savings with NFT achievements
- [ ] Build ESP32 IoT device integration
- [ ] Add backend API for IoT devices to query bounties

---

## 📊 API Integration Details

### Electricity Maps API
**Endpoint:** `https://api.electricitymap.org/v3/carbon-intensity/latest?zone=US-CAL-CISO`  
**Headers:** `auth-token: pCLyt2braf6LlZALA4QH`  
**Response:**
```json
{
  "zone": "US-CAL-CISO",
  "carbonIntensity": 450,
  "datetime": "2025-11-01T20:00:00.000Z"
}
```

### Smart Contract Integration
**Create Bounty:**
```javascript
const rewardPerKwh = ethers.parseUnits("1", 6); // 1 USDC
const totalBudget = ethers.parseUnits("100", 6); // 100 USDC
const deadline = Math.floor(Date.now() / 1000) + 1800; // 30 min

await usdcContract.approve(CONTRACT_ADDRESS, totalBudget);
await contract.createBounty(rewardPerKwh, totalBudget, deadline);
```

**Claim Reward:**
```javascript
const bountyId = 1;
const kwhSaved = 2;
const proofHash = ethers.id("sensor-data-hash");
await contract.claimReward(bountyId, kwhSaved, proofHash);
```

### IoT Device Integration (ESP32)
```python
import urequests, time

API_URL = "http://backend.local/api"

while True:
    bounties = urequests.get(f"{API_URL}/active").json()
    if bounties:
        print("Grid alert! Reducing consumption...")
        kwh_saved = measure_savings()
        urequests.post(f"{API_URL}/claim", json={
            "bountyId": bounties[0]['id'],
            "kwhSaved": kwh_saved,
            "proofHash": generate_proof()
        })
    time.sleep(30)
```

---

**Document Version:** 2.0 — Updated with deployment status  
**Authors:** Team FantasticFour — Assets on Chain Hackathon, San Francisco 2025  
© 2025 — Aura Autonomous Utility Response Agent Project
