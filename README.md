
# ⚡ AuraContract — Autonomous Utility Response Agent  
### by Team **FantasticFour**

> Smart Contract backend for the “Aura” system — an AI-powered, blockchain-based Demand Response network that rewards users for saving electricity during grid stress events.

---

## 🌍 Overview

The **Aura Contract** is the blockchain heart of **Aura**, an AI + IoT + Blockchain system that automates energy-saving behavior and instantly rewards participants in USDC (mocked ERC-20).  
When grid data (via the Electricity Maps API) shows high carbon intensity or demand, the **Aura AI Agent** triggers a “Demand Response Bounty” on-chain.  
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
| `getActiveBounties()` | (Optional) Returns all open bounties |

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
│   └── AuraBounty.sol
├── scripts/
│   ├── deploy.js
│   └── test.js
├── test/
│   └── AuraBounty.test.js
├── .env.example
├── hardhat.config.js
├── package.json
└── README.md
```

---

## 🚀 Setup & Deployment

### 1️⃣ Prerequisites
- Node.js ≥ 18  
- Hardhat (`npx hardhat --version`)  
- Testnet account (Alchemy / Infura)  
- MetaMask wallet with test ETH (Sepolia)  
- Mock USDC contract (can use OpenZeppelin faucet)

### 2️⃣ Install Dependencies
```bash
git clone https://github.com/Autonomous-Utility-Response-Agent/AuraContract.git
cd AuraContract
npm install
```

### 3️⃣ Environment Variables
Create `.env`:
```bash
PRIVATE_KEY=your_wallet_private_key
RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your_key
USDC_ADDRESS=0x...   # mock USDC or test token
```

### 4️⃣ Compile
```bash
npx hardhat compile
```

### 5️⃣ Deploy
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

You’ll get a contract address like:
```
Deployed AuraBounty to 0x1234abcd...5678
```

---

## 🧩 Example Integration (Node.js)

**Aura AI Agent → create bounty:**
```js
import axios from "axios";
import { ethers } from "ethers";

const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, abi, wallet);

const rewardPerKwh = 1; // 1 USDC per kWh
const totalBudget = 100; // total USDC
const deadline = Math.floor(Date.now() / 1000) + 1800; // 30 min

await contract.createBounty(rewardPerKwh, totalBudget, deadline);
```

---

## 🧠 Example Interaction (IoT Claim)

**ESP32 Python (simplified):**
```python
import urequests, time

while True:
    bounties = urequests.get("http://backend.local/api/active").json()
    if bounties:
        print("Grid alert! Turning off lamp...")
        # Save 1 kWh, send proof
        urequests.post("http://backend.local/api/claim", json={
            "bountyId": bounties[0]['id'],
            "kwhSaved": 1,
            "proofHash": "0xdeadbeef"
        })
    time.sleep(30)
```

---

## 🧩 Testing

Local testnet:
```bash
npx hardhat node
npx hardhat run scripts/deploy.js --network localhost
npx hardhat test
```

Run JS tests:
```bash
npx hardhat test test/AuraBounty.test.js
```

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
