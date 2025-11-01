// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AuraBounty {
    struct Bounty {
        uint256 id;
        uint256 rewardPerKwh;
        uint256 totalBudget;
        uint256 remainingBudget;
        uint256 deadline;
        bool active;
    }

    IERC20 public usdcToken;
    uint256 public bountyCounter;
    mapping(uint256 => Bounty) public bounties;

    event BountyCreated(uint256 indexed id, uint256 rewardPerKwh, uint256 totalBudget, uint256 deadline);
    event RewardClaimed(uint256 indexed id, address indexed claimant, uint256 kwhSaved, uint256 reward);
    event BountyClosed(uint256 indexed id, uint256 remainingBudget);

    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);
    }

    function createBounty(uint256 rewardPerKwh, uint256 totalBudget, uint256 deadline) external {
        require(deadline > block.timestamp, "Deadline must be in future");
        require(totalBudget > 0, "Budget must be positive");
        
        usdcToken.transferFrom(msg.sender, address(this), totalBudget);
        
        bountyCounter++;
        bounties[bountyCounter] = Bounty({
            id: bountyCounter,
            rewardPerKwh: rewardPerKwh,
            totalBudget: totalBudget,
            remainingBudget: totalBudget,
            deadline: deadline,
            active: true
        });

        emit BountyCreated(bountyCounter, rewardPerKwh, totalBudget, deadline);
    }

    function claimReward(uint256 bountyId, uint256 kwhSaved, bytes32 proofHash) external {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.active, "Bounty not active");
        require(block.timestamp <= bounty.deadline, "Bounty expired");
        
        uint256 reward = kwhSaved * bounty.rewardPerKwh;
        require(reward <= bounty.remainingBudget, "Insufficient budget");
        
        bounty.remainingBudget -= reward;
        usdcToken.transfer(msg.sender, reward);

        emit RewardClaimed(bountyId, msg.sender, kwhSaved, reward);
    }

    function closeBounty(uint256 bountyId) external {
        Bounty storage bounty = bounties[bountyId];
        require(bounty.active, "Already closed");
        require(block.timestamp > bounty.deadline, "Not expired yet");
        
        bounty.active = false;
        if (bounty.remainingBudget > 0) {
            usdcToken.transfer(msg.sender, bounty.remainingBudget);
        }

        emit BountyClosed(bountyId, bounty.remainingBudget);
    }

    function getActiveBounties() external view returns (uint256[] memory) {
        uint256 activeCount = 0;
        for (uint256 i = 1; i <= bountyCounter; i++) {
            if (bounties[i].active && block.timestamp <= bounties[i].deadline) {
                activeCount++;
            }
        }
        
        uint256[] memory activeBountyIds = new uint256[](activeCount);
        uint256 index = 0;
        for (uint256 i = 1; i <= bountyCounter; i++) {
            if (bounties[i].active && block.timestamp <= bounties[i].deadline) {
                activeBountyIds[index] = i;
                index++;
            }
        }
        
        return activeBountyIds;
    }
}
