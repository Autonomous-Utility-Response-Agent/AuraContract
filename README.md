# ⚡ AuraContract — Autonomous Utility Response Agent  
### by Team **FantasticFour**

> Smart Contract backend for the "Aura" system — an AI-powered, blockchain-based Demand Response network that rewards users for saving electricity during grid stress events.

---

## ✅ Live Deployment on Sepolia Testnet

**Jury: View our deployed contracts here:**

- **MockUSDC**: [`0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce`](https://sepolia.etherscan.io/address/0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce)
- **AuraBounty**: [`0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1`](https://sepolia.etherscan.io/address/0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1)

---

## 🌍 Overview

The **Aura Contract** is the blockchain heart of **Aura**, an AI + IoT + Blockchain system that automates energy-saving behavior and instantly rewards participants in USDC (mocked ERC-20).  
When grid data (via the Electricity Maps API) shows high carbon intensity or demand, the **Aura AI Agent** triggers a "Demand Response Bounty" on-chain.  
IoT devices (e.g., ESP32 smart lamps) detect this bounty, reduce energy usage, and claim a verified reward.

---

## 🧩 Architecture

```
Grid Data (Electricity Maps API)
           ↓
     Aura AI Agent (Node.js)
           ↓
  ┌──────────────────────────┐
  │  Smart Contract (AuraBounty.sol) │
  │  createBounty / claimReward / closeBounty │
  └──────────────────────────┘
           ↓
 IoT Device (ESP32) → saves energy, sends proof
           ↓
   Oracle / Mock Chainlink verifies claim
           ↓
   Instant payout in USDC (mock)
```

---

## ⚙️ Contract Details

### `AuraBounty.sol`

| Function | Description |
|-----------|--------------|
| `createBounty(uint rewardPerKwh, uint totalBudget, uint deadline)` | Creates a new energy-saving bounty funded in USDC |
| `claimReward(uint bountyId, uint kwhSaved, bytes32 proofHash)` | IoT or backend device claims reward for verified energy savings |
| `closeBounty(uint bountyId)` | Closes expired bounty |
| `getActiveBounties()` | Returns all open bounties |

**Contract Events**
- `BountyCreated(uint id, uint rewardPerKwh, uint deadline)`
- `RewardClaimed(uint id, address claimant, uint reward)`
- `BountyClosed(uint id)`

---

## 🧠 Technical Stack

| Layer | Tech |
|-------|------|
| Smart Contract | Solidity ^0.8.20, Hardhat |
| Token | ERC-20 Mock USDC (OpenZeppelin) |
| Backend / AI Agent | Node.js + ethers.js + axios |
| IoT Device | ESP32 (MicroPython or Arduino) |
| Oracle | Mocked Chainlink Functions |

---

## 🧱 Folder Structure

```
AuraContract/
├── contracts/
│   ├── AuraBounty.sol      # Main bounty contract
│   └── MockUSDC.sol         # Test USDC token
├── scripts/
│   └── deploy.js            # Deployment script
├── ai_agent.js              # AI monitoring agent
├── hardhat.config.js        # Hardhat configuration
├── .env                     # Environment variables
├── package.json
├── TODO.md                  # Implementation checklist
└── README.md
```

---

## 🚀 Running the AI Agent

The AI agent monitors the California grid (US-CAL-CISO) and automatically creates bounties when carbon intensity exceeds 400 gCO2eq/kWh.

### Start the Agent

```bash
node ai_agent.js
```

### What It Does

1. **Monitors** Electricity Maps API every 60 seconds
2. **Detects** high carbon intensity (> 400 gCO2eq/kWh)
3. **Creates** a bounty on-chain with:
   - Reward: 1 USDC per kWh saved
   - Budget: 100 USDC
   - Duration: 30 minutes
4. **Logs** transaction hash and Etherscan link

### Example Output

```
🤖 Aura AI Agent Started
📍 Monitoring: US-CAL-CISO
🔗 Contract: 0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1

🔍 Checking grid status...
📊 Carbon Intensity: 450 gCO2eq/kWh
⚠️  HIGH CARBON DETECTED — Creating bounty!
💰 Approving USDC...
🚀 Creating bounty...
✅ Bounty created!
   TX: 0xabc123...
   View: https://sepolia.etherscan.io/tx/0xabc123...
```

---

## 🔌 API Integration Guide

### Electricity Maps API

The AI agent uses the Electricity Maps API to monitor grid carbon intensity:

**Endpoint:**
```
GET https://api.electricitymap.org/v3/carbon-intensity/latest?zone=US-CAL-CISO
```

**Headers:**
```
auth-token: your_api_token
```

**Response:**
```json
{
  "zone": "US-CAL-CISO",
  "carbonIntensity": 450,
  "datetime": "2025-11-01T20:00:00.000Z"
}
```

**Supported Zones:**
- `US-CAL-CISO` - California
- `US-TEX-ERCO` - Texas
- `US-NY-NYIS` - New York
- [Full list](https://api.electricitymap.org/v3/zones)

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

**Example Python (MicroPython):**
```python
import urequests, time

API_URL = "http://backend.local/api"

while True:
    # Check for active bounties
    bounties = urequests.get(f"{API_URL}/active").json()
    
    if bounties:
        print("Grid alert! Reducing consumption...")
        # Turn off lamp, measure savings
        kwh_saved = measure_savings()
        
        # Claim reward
        urequests.post(f"{API_URL}/claim", json={
            "bountyId": bounties[0]['id'],
            "kwhSaved": kwh_saved,
            "proofHash": generate_proof()
        })
    
    time.sleep(30)
```

---

## 🧪 Verifying Contracts Work

### Method 1: Check on Etherscan

Visit the contract pages and view transactions:
- [MockUSDC Transactions](https://sepolia.etherscan.io/address/0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce)
- [AuraBounty Transactions](https://sepolia.etherscan.io/address/0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1)

### Method 2: Hardhat Console

```bash
npx hardhat console --network sepolia
```

**Check active bounties:**
```javascript
const contract = await ethers.getContractAt("AuraBounty", "0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1");
const bounties = await contract.getActiveBounties();
console.log("Active bounties:", bounties);
```

**Check bounty details:**
```javascript
const bounty = await contract.bounties(1);
console.log("Bounty 1:", bounty);
```

**Simulate IoT device claiming reward:**
```javascript
const bountyId = 1;
const kwhSaved = 2; // 2 kWh saved
const proofHash = ethers.id("proof-data");
const tx = await contract.claimReward(bountyId, kwhSaved, proofHash);
await tx.wait();
console.log("Reward claimed!");
```

### Method 3: Read Contract on Etherscan

1. Go to [AuraBounty Contract](https://sepolia.etherscan.io/address/0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1#readContract)
2. Click "Read Contract"
3. Call `getActiveBounties()` to see all active bounties
4. Call `bounties(uint256)` with bounty ID to see details

---

## 🧠 Team — *FantasticFour*

| Member | Role | Alias |
|---------|------|--------|
| **Denis** | Smart Contract Developer | Treasury Architect |
| **Valerii** | AI & Visualization Developer | Grid Whisperer |
| **Tomas** | IoT Engineer | Device Responder |
| **Godsfavour** | Backend Developer | System Integrator |

---

## 🧩 Future Work
- Add Chainlink oracle verification  
- Tokenize energy credits (AuraToken)  
- Add reputation-based rewards  
- Deploy dashboard (Next.js / Streamlit)  
- Integrate with real IoT smart plugs  

---

## 🪙 License
MIT License © 2025 FantasticFour  
Built for **Assets on Chain Hackathon — San Francisco**
