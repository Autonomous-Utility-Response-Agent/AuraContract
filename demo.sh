#!/usr/bin/env bash

set -e

# Colors
GRAY='\033[0;90m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

VERBOSE=0

show_help() {
    echo -e "${GREEN}⚡ Aura Contract Demo Script${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./demo.sh [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Show detailed curl calls and responses"
    echo ""
    echo "  --check-grid            Check current grid carbon intensity"
    echo "  --check-balance         Check wallet USDC balance"
    echo "  --create-bounty         Create a new bounty (requires USDC approval)"
    echo "  --list-bounties         List all active bounties"
    echo "  --claim-reward ID KWH   Claim reward for bounty ID with KWH saved"
    echo "  --close-bounty ID       Close expired bounty ID"
    echo ""
    echo "  --run-agent             Start the AI monitoring agent"
    echo "  --full-demo             Run complete demo flow (interactive)"
    echo "  --auto-demo             Run automated demo (press key after each step)"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./demo.sh --check-grid"
    echo "  ./demo.sh --list-bounties -v"
    echo "  ./demo.sh --create-bounty"
    echo "  ./demo.sh --claim-reward 1 2"
    echo "  ./demo.sh --auto-demo"
    echo ""
    echo -e "${YELLOW}Deployed Contracts:${NC}"
    echo -e "  MockUSDC:   ${BLUE}0x2e6f4531E112fD6E0637be9d8736aE8a7275EAce${NC}"
    echo -e "  AuraBounty: ${BLUE}0x686297B1f4bfc7DD18Da16716c3C2817eC4591A1${NC}"
    echo ""
    echo "  View on Etherscan:"
    echo "  https://sepolia.etherscan.io/address/${CONTRACT_ADDRESS}"
    echo ""
}

log_verbose() {
    if [ $VERBOSE -eq 1 ]; then
        echo -e "${GRAY}$1${NC}"
    fi
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_grid() {
    echo -e "${YELLOW}🔍 Checking Grid Status...${NC}"
    
    CURL_CMD="curl -s -H 'auth-token: ${ELECTRICITYMAPS_TOKEN}' \
        'https://api.electricitymap.org/v3/carbon-intensity/latest?zone=US-CAL-CISO'"
    
    log_verbose "Running: $CURL_CMD"
    
    RESPONSE=$(eval $CURL_CMD)
    
    log_verbose "Response: $RESPONSE"
    
    CARBON=$(echo $RESPONSE | grep -o '"carbonIntensity":[0-9]*' | grep -o '[0-9]*')
    
    if [ -n "$CARBON" ]; then
        log_success "Carbon Intensity: ${CARBON} gCO2eq/kWh"
        
        if [ $CARBON -gt 400 ]; then
            echo -e "${RED}⚠️  HIGH CARBON - Bounty should be created!${NC}"
        else
            echo -e "${GREEN}✅ Grid stable - No action needed${NC}"
        fi
    else
        log_error "Failed to fetch carbon intensity"
    fi
}

check_balance() {
    echo -e "${YELLOW}💰 Checking USDC Balance...${NC}"
    
    log_verbose "Running: npx hardhat console --network sepolia"
    
    SCRIPT="const usdc = await ethers.getContractAt('MockUSDC', '${USDC_ADDRESS}'); \
            const balance = await usdc.balanceOf('${WALLET_ADDRESS}'); \
            console.log(ethers.formatUnits(balance, 6));"
    
    BALANCE=$(echo "$SCRIPT" | npx hardhat console --network sepolia 2>/dev/null | tail -1)
    
    log_success "Balance: ${BALANCE} USDC"
}

list_bounties() {
    echo -e "${YELLOW}📋 Listing Active Bounties...${NC}"
    
    SCRIPT="const contract = await ethers.getContractAt('AuraBounty', '${CONTRACT_ADDRESS}'); \
            const bounties = await contract.getActiveBounties(); \
            console.log(JSON.stringify(bounties));"
    
    log_verbose "Querying contract: ${CONTRACT_ADDRESS}"
    
    BOUNTIES=$(echo "$SCRIPT" | npx hardhat console --network sepolia 2>/dev/null | tail -1)
    
    log_verbose "Response: $BOUNTIES"
    
    if [ "$BOUNTIES" = "[]" ]; then
        log_info "No active bounties"
    else
        log_success "Active bounties: $BOUNTIES"
    fi
}

create_bounty() {
    echo -e "${YELLOW}🚀 Creating Bounty...${NC}"
    
    REWARD="1000000"  # 1 USDC (6 decimals)
    BUDGET="100000000"  # 100 USDC
    DEADLINE=$(($(date +%s) + 1800))  # 30 minutes
    
    log_info "Reward: 1 USDC per kWh"
    log_info "Budget: 100 USDC"
    log_info "Duration: 30 minutes"
    
    SCRIPT="const usdc = await ethers.getContractAt('MockUSDC', '${USDC_ADDRESS}'); \
            const contract = await ethers.getContractAt('AuraBounty', '${CONTRACT_ADDRESS}'); \
            console.log('Approving USDC...'); \
            const approveTx = await usdc.approve('${CONTRACT_ADDRESS}', '${BUDGET}'); \
            await approveTx.wait(); \
            console.log('Creating bounty...'); \
            const tx = await contract.createBounty('${REWARD}', '${BUDGET}', ${DEADLINE}); \
            const receipt = await tx.wait(); \
            console.log('TX:' + receipt.hash);"
    
    log_verbose "Executing transaction..."
    
    echo "$SCRIPT" | npx hardhat console --network sepolia 2>/dev/null | while read line; do
        if [[ $line == TX:* ]]; then
            HASH=${line#TX:}
            log_success "Bounty created!"
            echo -e "${BLUE}   View: https://sepolia.etherscan.io/tx/${HASH}${NC}"
        else
            log_verbose "$line"
        fi
    done
}

claim_reward() {
    BOUNTY_ID=$1
    KWH_SAVED=$2
    
    if [ -z "$BOUNTY_ID" ] || [ -z "$KWH_SAVED" ]; then
        log_error "Usage: --claim-reward BOUNTY_ID KWH_SAVED"
        exit 1
    fi
    
    echo -e "${YELLOW}💎 Claiming Reward...${NC}"
    
    log_info "Bounty ID: ${BOUNTY_ID}"
    log_info "kWh Saved: ${KWH_SAVED}"
    
    PROOF_HASH="0x$(echo -n "proof-${BOUNTY_ID}-${KWH_SAVED}" | sha256sum | cut -d' ' -f1)"
    
    SCRIPT="const contract = await ethers.getContractAt('AuraBounty', '${CONTRACT_ADDRESS}'); \
            const tx = await contract.claimReward(${BOUNTY_ID}, ${KWH_SAVED}, '${PROOF_HASH}'); \
            const receipt = await tx.wait(); \
            console.log('TX:' + receipt.hash);"
    
    log_verbose "Proof hash: ${PROOF_HASH}"
    
    echo "$SCRIPT" | npx hardhat console --network sepolia 2>/dev/null | while read line; do
        if [[ $line == TX:* ]]; then
            HASH=${line#TX:}
            log_success "Reward claimed!"
            echo -e "${BLUE}   View: https://sepolia.etherscan.io/tx/${HASH}${NC}"
        else
            log_verbose "$line"
        fi
    done
}

close_bounty() {
    BOUNTY_ID=$1
    
    if [ -z "$BOUNTY_ID" ]; then
        log_error "Usage: --close-bounty BOUNTY_ID"
        exit 1
    fi
    
    echo -e "${YELLOW}🔒 Closing Bounty...${NC}"
    
    SCRIPT="const contract = await ethers.getContractAt('AuraBounty', '${CONTRACT_ADDRESS}'); \
            const tx = await contract.closeBounty(${BOUNTY_ID}); \
            const receipt = await tx.wait(); \
            console.log('TX:' + receipt.hash);"
    
    echo "$SCRIPT" | npx hardhat console --network sepolia 2>/dev/null | while read line; do
        if [[ $line == TX:* ]]; then
            HASH=${line#TX:}
            log_success "Bounty closed!"
            echo -e "${BLUE}   View: https://sepolia.etherscan.io/tx/${HASH}${NC}"
        else
            log_verbose "$line"
        fi
    done
}

run_agent() {
    echo -e "${YELLOW}🤖 Starting AI Agent...${NC}"
    log_info "Press Ctrl+C to stop"
    echo ""
    node ai_agent.js
}

full_demo() {
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  🎬 Aura Contract Full Demo${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    
    check_grid
    echo ""
    
    check_balance
    echo ""
    
    list_bounties
    echo ""
    
    read -p "Create a test bounty? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_bounty
        echo ""
        sleep 3
        list_bounties
        echo ""
    fi
    
    read -p "Claim reward for bounty 1 with 2 kWh saved? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        claim_reward 1 2
        echo ""
        sleep 3
        check_balance
    fi
    
    echo ""
    echo -e "${GREEN}✅ Demo complete!${NC}"
}

wait_for_key() {
    echo ""
    echo -e "${YELLOW}Press any key to continue...${NC}"
    read -n 1 -s
    echo ""
}

auto_demo() {
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  🎬 Aura Automated Demo${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}This demo will show:${NC}"
    echo "  1. Check grid carbon intensity"
    echo "  2. Check wallet USDC balance"
    echo "  3. Create first demand response bounty"
    echo "  4. List active bounties"
    echo "  5. Simulate IoT device claiming reward"
    echo "  6. Create second bounty"
    echo "  7. Claim reward from second bounty"
    echo "  8. Check final balance"
    echo ""
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 1: Check Grid Status ━━━${NC}"
    check_grid
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 2: Check Initial Balance ━━━${NC}"
    check_balance
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 3: Create First Bounty ━━━${NC}"
    echo -e "${BLUE}Creating bounty: 1 USDC/kWh, 100 USDC budget, 30 min duration${NC}"
    create_bounty
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 4: List Active Bounties ━━━${NC}"
    list_bounties
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 5: IoT Device #1 Claims Reward ━━━${NC}"
    echo -e "${BLUE}Device saved 2 kWh, claiming 2 USDC reward${NC}"
    claim_reward 1 2
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 6: Create Second Bounty ━━━${NC}"
    echo -e "${BLUE}Grid stress continues, creating another bounty${NC}"
    create_bounty
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 7: IoT Device #2 Claims Reward ━━━${NC}"
    echo -e "${BLUE}Another device saved 3 kWh, claiming 3 USDC reward${NC}"
    claim_reward 2 3
    wait_for_key
    
    echo -e "${GREEN}━━━ Step 8: Check Final Balance ━━━${NC}"
    check_balance
    echo ""
    
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo -e "${GREEN}  ✅ Demo Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════${NC}"
    echo ""
    echo -e "${BLUE}Transactions created:${NC}"
    echo "  • 2 bounties created (200 USDC total)"
    echo "  • 2 rewards claimed (5 USDC paid out)"
    echo ""
    echo -e "${BLUE}View all transactions on Etherscan:${NC}"
    echo "https://sepolia.etherscan.io/address/${CONTRACT_ADDRESS}"
}

# Parse arguments
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        --check-grid)
            check_grid
            exit 0
            ;;
        --check-balance)
            check_balance
            exit 0
            ;;
        --list-bounties)
            list_bounties
            exit 0
            ;;
        --create-bounty)
            create_bounty
            exit 0
            ;;
        --claim-reward)
            claim_reward "$2" "$3"
            exit 0
            ;;
        --close-bounty)
            close_bounty "$2"
            exit 0
            ;;
        --run-agent)
            run_agent
            exit 0
            ;;
        --full-demo)
            full_demo
            exit 0
            ;;
        --auto-demo|auto)
            auto_demo
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done
