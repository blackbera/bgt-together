// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { VRFConsumerBaseV2 } from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import { VRFCoordinatorV2Interface } from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import { IBerachainRewardsVault } from "./interfaces/IBerachainRewardsVault.sol";

contract BGTTogetherVault is ERC4626, VRFConsumerBaseV2 {
    using SafeERC20 for IERC20;

    // Constants 
    uint256 private constant EPOCH_DURATION = 7 days;
    
    // State variables
    IBerachainRewardsVault public immutable rewardsVault;
    VRFCoordinatorV2Interface public immutable vrfCoordinator;
    
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;
    uint32 public immutable callbackGasLimit;
    
    uint256 public lastHarvestTime;
    uint256 public currentEpoch;
    address public pendingWinner;
    
    // Events
    event PrizeAwarded(address winner, uint256 amount, uint256 epoch);
    event HarvestInitiated(uint256 epoch);
    
    constructor(
        address _asset,
        address _rewardsVault,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) 
        ERC4626(IERC20(_asset))
        ERC20("BGT Together Vault", "BGT-TV")
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        rewardsVault = IBerachainRewardsVault(_rewardsVault);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        callbackGasLimit = 100000;
        
        // Approve rewards vault to spend our asset
        IERC20(_asset).approve(_rewardsVault, type(uint256).max);
        
        lastHarvestTime = block.timestamp;
    }

    // Override _deposit to stake in rewards vault
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        super._deposit(caller, receiver, assets, shares);
        rewardsVault.stake(assets);
    }

    // Override _withdraw to withdraw from rewards vault
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        rewardsVault.withdraw(assets);
        super._withdraw(caller, receiver, owner, assets, shares);
    }

    // Harvest rewards and initiate lottery
    function harvest() external {
        require(block.timestamp >= lastHarvestTime + EPOCH_DURATION, "Too early to harvest");
        
        // Get rewards from vault
        uint256 rewards = rewardsVault.getReward(address(this), address(this));
        require(rewards > 0, "No rewards to harvest");
        
        currentEpoch++;
        lastHarvestTime = block.timestamp;
        
        // Request random winner
        vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            3, // requestConfirmations
            callbackGasLimit,
            1 // numWords
        );
        
        emit HarvestInitiated(currentEpoch);
    }

    // VRF Callback to select winner
    function fulfillRandomWords(uint256, uint256[] memory randomWords) internal override {
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "No participants");
        
        // Select winner based on random number
        uint256 winnerIndex = randomWords[0] % totalSupply;
        address winner = _selectWinner(winnerIndex);
        
        // Transfer rewards to winner
        uint256 prizeAmount = IERC20(rewardToken()).balanceOf(address(this));
        IERC20(rewardToken()).safeTransfer(winner, prizeAmount);
        
        emit PrizeAwarded(winner, prizeAmount, currentEpoch);
    }

    // Helper function to find winner based on index
    function _selectWinner(uint256 index) internal view returns (address) {
        uint256 current;
        for (uint i = 0; i < totalSupply(); i++) {
            current += balanceOf(address(uint160(i)));
            if (current > index) {
                return address(uint160(i));
            }
        }
        revert("Winner not found");
    }

    // Function to add incentives to rewards vault
    function addIncentive(
        address token,
        uint256 amount,
        uint256 incentiveRate
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(rewardsVault), amount);
        rewardsVault.addIncentive(token, amount, incentiveRate);
    }
}
