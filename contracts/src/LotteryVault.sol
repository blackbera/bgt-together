// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { GelatoVRFConsumerBase } from "vrf-contracts/GelatoVRFConsumerBase.sol";
import { IBerachainRewardsVault } from "contracts-monorepo/pol/interfaces/IBerachainRewardsVault.sol";
import { PrzHoney } from "./PrzHoney.sol";
import {console} from "forge-std/console.sol";

contract LotteryReceiptToken is ERC20 {
    constructor() ERC20("przHoney", "przHoney") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}

contract LotteryVault is GelatoVRFConsumerBase, Ownable {
    using SafeERC20 for IERC20;

    // Events
    event TicketPurchased(address indexed buyer, uint256 ticketId, uint256 amount);
    event LotteryWinner(address indexed winner, uint256 amount);
    event IncentiveAdded(uint256 amount);
    event DrawInitiated(uint256 lotteryId);
    event LotteryStarted(uint256 lotteryId, uint256 ticketPrice, uint256 endTime);
    event RewardClaimed(address indexed winner, uint256 amount);
    event ReceiptTokensBurned(address indexed user, uint256 amount);
    event WithdrawalFailed(address indexed participant, uint256 amount);
    event PrzHoneySet(address przHoney);

    // Errors
    error InvalidAmount();
    error LotteryNotEnded();
    error LotteryEnded();
    error NoParticipants();
    error DrawInProgress();
    error NoActiveLottery();
    error LotteryAlreadyActive();
    error InvalidTicketPrice();
    error InvalidDuration();
    error NotWinner();
    error InsufficientGasReserves();
    error StakingNotAllowed();
    error VRFRequestAlreadyPending();
    error VRFInvalidRoundId(uint256 roundId);
    error VRFInvalidRequestData();
    error VRFInvalidRandomness();
    error VRFInvalidParticipantCount();

    // Constants
    uint256 private constant PURCHASE_FEE = 100; // 1%
    uint256 private constant WINNER_FEE = 300; // 3%
    uint256 private constant FEE_DENOMINATOR = 10000;
    uint256 private constant MIN_GAS_RESERVE = 1 ether; // Minimum ETH to keep for gas
    address public immutable operator;

    // State variables
    IERC20 public paymentToken;
    PrzHoney public receiptToken;
    IBerachainRewardsVault public rewardVault;
    
    uint256 public lotteryEndTime;
    uint256 public currentLotteryId;
    uint256 public ticketPrice;
    uint256 public totalPool;
    
    bool public drawInProgress;
    bool public lotteryActive;
    
    // Mappings
    mapping(uint256 => address[]) public lotteryParticipants;
    mapping(address => uint256) public userTicketCount;
    mapping(uint256 => address) public lotteryWinners;
    mapping(uint256 => uint256) public lotteryPrizes;
    mapping(uint256 => bool) public prizesClaimed;
    mapping(address => uint256) public userReceiptTokenBalance;

    constructor(
        address _paymentToken,
        address _owner,
        address _rewardVault, 
        address _operatorAddress
    ) GelatoVRFConsumerBase() Ownable(_owner) {
        paymentToken = IERC20(_paymentToken);
        rewardVault = IBerachainRewardsVault(_rewardVault);
        currentLotteryId = 1;
        operator = _operatorAddress;
    }

    // Allow contract to receive ETH
    receive() external payable {}

    function claimReward(uint256 lotteryId) external {
        address winner = lotteryWinners[lotteryId];
        require(winner != address(0), "No winner for this lottery");
        require(!prizesClaimed[lotteryId], "Prize already claimed");
        
        uint256 prize = lotteryPrizes[lotteryId];
        require(prize > 0, "No prize available");

        prizesClaimed[lotteryId] = true;
        paymentToken.safeTransfer(winner, prize);

        // Burn receipt tokens from winner
        uint256 winnerTickets = userTicketCount[winner];
        receiptToken.burn(winner, winnerTickets);

        emit RewardClaimed(winner, prize);
        emit ReceiptTokensBurned(winner, winnerTickets);

        // Reset lottery
        _startNewLottery();
    }

    function _startNewLottery() internal {
        totalPool = 0;
        currentLotteryId += 1;
        lotteryEndTime = block.timestamp + 1 days;
        drawInProgress = false;
        lotteryActive = true;
    }

    function purchaseTicket(uint256 amount) external {
    // Check lottery state
    if (!lotteryActive) revert NoActiveLottery();
    if (block.timestamp >= lotteryEndTime) revert LotteryEnded();
    if (amount == 0) revert InvalidAmount();

    uint256 totalCost = amount * ticketPrice;
    /*
        Purchase Fee Calculation:
        =========================
        fee = (totalCost * PURCHASE_FEE) / FEE_DENOMINATOR
        where:
        - PURCHASE_FEE = 100 (1%)
        - FEE_DENOMINATOR = 10000
        
        Example for 1 BERA purchase:
            fee = (1 BERA * 100) / 10000
            fee = 0.01 BERA (1%)
        
        Final amount to pool = totalCost - fee
    */
    uint256 purchaseFee = (totalCost * PURCHASE_FEE) / FEE_DENOMINATOR;
    
    // Transfer total payment from user to vault
    paymentToken.safeTransferFrom(msg.sender, address(this), totalCost);
    // Add amount minus fee to prize pool
    totalPool += (totalCost - purchaseFee);
    
    // Mint receipt tokens to user for tracking participation
    receiptToken.mint(address(this), amount);
    receiptToken.approve(address(rewardVault), amount);
    rewardVault.delegateStake(msg.sender, amount);

    
    // Add purchase fee as incentive to rewards vault
    paymentToken.approve(address(rewardVault), purchaseFee);
    rewardVault.addIncentive(address(paymentToken), purchaseFee, 1);

    // Record participation for lottery drawing
    lotteryParticipants[currentLotteryId].push(msg.sender);
    userTicketCount[msg.sender] += amount;

    emit TicketPurchased(msg.sender, currentLotteryId, amount);
}

    function startLottery() external {
        if (lotteryActive) revert LotteryAlreadyActive();

        ticketPrice = 1 ether;
        lotteryEndTime = block.timestamp + 1 days;
        lotteryActive = true;

        emit LotteryStarted(currentLotteryId, ticketPrice, lotteryEndTime);
    }

    function initiateDraw() external {
        if (!lotteryActive) revert NoActiveLottery();
        if (block.timestamp < lotteryEndTime) revert LotteryNotEnded();
        if (lotteryParticipants[currentLotteryId].length == 0) revert NoParticipants();
        if (drawInProgress) revert DrawInProgress();
        
        drawInProgress = true;
        
        // Add logging
        console.log("Initiating draw for lottery:", currentLotteryId);
        console.log("Total pool:", totalPool);
        console.log("Participant count:", lotteryParticipants[currentLotteryId].length);
        
        bytes memory data = abi.encode(currentLotteryId, totalPool);
        bytes memory requestData = abi.encode(0, data);
        console.log("Request data prepared");
        
        _requestRandomness(requestData);
        console.log("Randomness requested");
        
        emit DrawInitiated(currentLotteryId);
    }

    function _fulfillRandomness(
        uint256 randomness,
        uint256 requestId,
        bytes memory extraData
    ) internal override {
        console.log("Fulfilling randomness");
        console.log("Randomness received:", randomness);
        console.log("Request ID:", requestId);
        
        (uint256 lotteryId, uint256 prizePool) = abi.decode(extraData, (uint256, uint256));
        console.log("Decoded lottery ID:", lotteryId);
        console.log("Decoded prize pool:", prizePool);
        
        uint256 participantCount = lotteryParticipants[lotteryId].length;
        if (participantCount == 0) revert VRFInvalidParticipantCount();
        
        console.log("Selecting winner from", participantCount, "participants");
        uint256 winnerIndex = randomness % participantCount;
        address winner = lotteryParticipants[lotteryId][winnerIndex];
        console.log("Selected winner:", winner);
        
        uint256 winnerFee = (prizePool * WINNER_FEE) / FEE_DENOMINATOR;
        uint256 winnerPrize = prizePool - winnerFee;
        console.log("Winner prize:", winnerPrize);
        console.log("Winner fee:", winnerFee);

        // Exit all participants from vault and burn their receipt tokens
        for (uint256 i = 0; i < participantCount; i++) {
            address participant = lotteryParticipants[lotteryId][i];
            uint256 participantStake = userTicketCount[participant];
            
            if (participantStake > 0) {
                console.log("Processing participant:", participant);
                console.log("Stake amount:", participantStake);
                
                try rewardVault.delegateWithdraw(participant, participantStake) {
                    receiptToken.burn(participant, participantStake);
                    userTicketCount[participant] = 0;
                    emit ReceiptTokensBurned(participant, participantStake);
                    console.log("Successfully processed participant");
                } catch {
                    console.log("Failed to process participant");
                    emit WithdrawalFailed(participant, participantStake);
                }
            }
        }

        // Transfer prize to winner
        console.log("Transferring prize to winner");
        paymentToken.safeTransfer(winner, winnerPrize);

        // Add winner fee as incentive
        console.log("Adding winner fee as incentive");
        paymentToken.approve(address(rewardVault), winnerFee);
        rewardVault.addIncentive(address(paymentToken), winnerFee, 1);

        lotteryWinners[lotteryId] = winner;
        lotteryPrizes[lotteryId] = winnerPrize;

        emit LotteryWinner(winner, winnerPrize);
        emit IncentiveAdded(winnerFee);

        // Reset lottery state
        console.log("Resetting lottery state");
        totalPool = 0;
        currentLotteryId += 1;
        lotteryEndTime = 0;
        drawInProgress = false;
        lotteryActive = false;
    }

    function getCurrentParticipants() external view returns (address[] memory) {
        return lotteryParticipants[currentLotteryId];
    }

    function getTimeRemaining() external view returns (uint256) {
        if (block.timestamp >= lotteryEndTime) return 0;
        return lotteryEndTime - block.timestamp;
    }

    function getLotteryInfo(uint256 lotteryId) external view returns (
        address winner,
        uint256 prize,
        address[] memory participants
    ) {
        winner = lotteryWinners[lotteryId];
        prize = lotteryPrizes[lotteryId];
        participants = lotteryParticipants[lotteryId];
    }

    // Add this function to expose the operator address
    function getOperator() external view returns (address) {
        return operator;
    }

    function _operator() internal view override returns (address) {
        return operator;
    }

    function withdrawExcessGas() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > MIN_GAS_RESERVE, "No excess gas to withdraw");
        uint256 excess = balance - MIN_GAS_RESERVE;
        (bool success, ) = owner().call{value: excess}("");
        require(success, "Gas withdrawal failed");
    }

    function setPrzHoney(address _przHoney) external onlyOwner {
        require(_przHoney != address(0), "Zero address not allowed");
        receiptToken = PrzHoney(_przHoney);
        PrzHoney(_przHoney).approve(address(rewardVault), type(uint256).max);
        emit PrzHoneySet(_przHoney);
    }
} 