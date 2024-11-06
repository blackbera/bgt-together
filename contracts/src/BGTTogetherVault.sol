// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC4626 } from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { GelatoVRFConsumerBase } from "vrf-contracts/GelatoVRFConsumerBase.sol";
import { IBerachainRewardsVault } from "contracts-monorepo/src/pol/interfaces/IBerachainRewardsVault.sol";

/* 
Feedback from Manny  
- How does the end claiming work? 
- If the prize tokens are transferrable, how does it affect the underlying lottery? 
*/

abstract contract BGTTogetherVault is ERC4626, GelatoVRFConsumerBase {
    using SafeERC20 for IERC20;

    // Constants 
    uint256 private constant EPOCH_DURATION = 7 days;
    
    // State variables
    IBerachainRewardsVault public immutable rewardsVault;
    
    uint256 public lastHarvestTime;
    uint256 public currentEpoch;
    
    // Track winners for each epoch
    mapping(uint256 => address) public epochWinners;
    mapping(uint256 => uint256) public epochPrizeAmounts;
    
    // Events
    event PrizeAwarded(address winner, uint256 amount, uint256 epoch);
    event HarvestInitiated(uint256 epoch); 
    
    constructor(
        address _asset,
        address _rewardsVault,
        string memory _name,
        string memory _symbol
    ) 
        ERC4626(IERC20(_asset))
        ERC20(_name, _symbol)
        GelatoVRFConsumerBase()
    {
        rewardsVault = IBerachainRewardsVault(_rewardsVault);
        
        // Approve rewards vault to spend our asset
        IERC20(_asset).approve(_rewardsVault, type(uint256).max);
        
        lastHarvestTime = block.timestamp;
    }

    function depositReceiptTokens(uint256 assets) internal returns (uint256 shares) {
        shares = deposit(assets, address(this));
        rewardsVault.stake(assets);
        
        return shares;
    }

    function withdrawReceiptTokens(uint256 assets) internal returns (uint256 shares) {
        rewardsVault.withdraw(assets);
        shares = withdraw(assets, address(this), address(this));
        return shares;
    }

    // Harvest rewards and initiate lottery
    function harvest() external {
        require(block.timestamp >= lastHarvestTime + EPOCH_DURATION, "Too early to harvest");
        
        // Get rewards from vault
        uint256 rewards = rewardsVault.getReward(address(this), address(this));
        require(rewards > 0, "No rewards to harvest");
        
        currentEpoch++;
        lastHarvestTime = block.timestamp;
        
        // Request random winner using Gelato VRF
        bytes memory data = abi.encode(currentEpoch);
        _requestRandomness(data);
        
        emit HarvestInitiated(currentEpoch);
    }

    // Gelato VRF Callback
    function _fulfillRandomness(
        uint256 randomness,
        uint256 requestId,
        bytes memory extraData
    ) internal virtual override {
        uint256 totalSupply = totalSupply();
        require(totalSupply > 0, "No participants");
        
        uint256 winnerIndex = randomness % totalSupply;
        address winner = _selectWinner(winnerIndex);
        
        uint256 prizeAmount = rewardsVault.getReward(address(this), winner);
        
        uint256 epoch = abi.decode(extraData, (uint256));
        epochWinners[epoch] = winner;
        epochPrizeAmounts[epoch] = prizeAmount;
        
        emit PrizeAwarded(winner, prizeAmount, epoch);
    }

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

    function addIncentive(
        address token,
        uint256 amount,
        uint256 incentiveRate
    ) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(rewardsVault), amount);
        rewardsVault.addIncentive(token, amount, incentiveRate);
    }

    // Getter function to get winner and prize amount for a specific epoch
    function getEpochWinnerInfo(uint256 epoch) external view returns (address winner, uint256 prizeAmount) {
        winner = epochWinners[epoch];
        prizeAmount = epochPrizeAmounts[epoch];
    }

    // Get all winners for a range of epochs
    function getEpochWinners(uint256 startEpoch, uint256 endEpoch) 
        external 
        view 
        returns (
            address[] memory winners,
            uint256[] memory prizes
        ) 
    {
        require(endEpoch >= startEpoch, "Invalid range");
        uint256 size = endEpoch - startEpoch + 1;
        
        winners = new address[](size);
        prizes = new uint256[](size);
        
        for (uint256 i = 0; i < size; i++) {
            uint256 epoch = startEpoch + i;
            winners[i] = epochWinners[epoch];
            prizes[i] = epochPrizeAmounts[epoch];
        }
    }
    
    function getCurrentVaultRewards() public view returns (uint256) {
        return rewardsVault.earned(address(this));
    }

    function _operator() internal view virtual override returns (address) {
        return 0xB38D2cF1024731d4cAcD8ED70BDa77aC93022911;
    }
}
