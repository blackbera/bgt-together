// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { GelatoVRFConsumerBase } from "vrf-contracts/GelatoVRFConsumerBase.sol";
import { IBerachainRewardsVault } from "contracts-monorepo/src/pol/interfaces/IBerachainRewardsVault.sol";

contract LotteryVault is 
    Initializable, 
    PausableUpgradeable, 
    ReentrancyGuardUpgradeable,
    GelatoVRFConsumerBase 
{
    using SafeERC20 for IERC20;

    // Events
    event TicketPurchased(address indexed buyer, uint256 ticketId, uint256 amount);
    event LotteryWinner(address indexed winner, uint256 amount);
    event IncentiveAdded(uint256 amount);
    event DrawInitiated(uint256 lotteryId);

    // Errors
    error InvalidAmount();
    error LotteryNotEnded();
    error LotteryEnded();
    error NotAuthorized();
    error NoParticipants();
    error DrawInProgress();

    // Constants
    uint256 private constant PURCHASE_FEE = 100; // 1%
    uint256 private constant WINNER_FEE = 300; // 3%
    uint256 private constant FEE_DENOMINATOR = 10000;

    // State variables
    IERC20 public paymentToken;
    IERC20 public incentiveToken;
    IBerachainRewardsVault public berachainVault;
    
    uint256 public lotteryEndTime;
    uint256 public currentLotteryId;
    uint256 public ticketPrice;
    uint256 public totalPool;
    
    bool public drawInProgress;
    
    // Mapping of lottery ID to participant addresses
    mapping(uint256 => address[]) public lotteryParticipants;
    // Mapping of address to ticket count for current lottery
    mapping(address => uint256) public userTicketCount;
    // Mapping to track lottery results
    mapping(uint256 => address) public lotteryWinners;
    mapping(uint256 => uint256) public lotteryPrizes;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _paymentToken,
        address _incentiveToken,
        address _berachainVault,
        uint256 _ticketPrice
    ) external initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        paymentToken = IERC20(_paymentToken);
        incentiveToken = IERC20(_incentiveToken);
        berachainVault = IBerachainRewardsVault(_berachainVault);
        ticketPrice = _ticketPrice;

        lotteryEndTime = block.timestamp + 1 days;
        currentLotteryId = 1;
    }

    function purchaseTicket(uint256 amount) external nonReentrant whenNotPaused {
        if (block.timestamp >= lotteryEndTime) revert LotteryEnded();
        if (amount == 0) revert InvalidAmount();

        uint256 totalCost = amount * ticketPrice;
        uint256 purchaseFee = (totalCost * PURCHASE_FEE) / FEE_DENOMINATOR;
        
        paymentToken.safeTransferFrom(msg.sender, address(this), totalCost);
        totalPool += (totalCost - purchaseFee);
        
        // Mint incentive tokens and delegate stake them
        incentiveToken.safeTransfer(msg.sender, amount);
        incentiveToken.approve(address(berachainVault), amount);
        berachainVault.delegateStake(msg.sender, amount);

        // Add purchase fee as incentive
        paymentToken.approve(address(berachainVault), purchaseFee);
        berachainVault.addIncentive(address(paymentToken), purchaseFee, 0);

        // Record participation
        lotteryParticipants[currentLotteryId].push(msg.sender);
        userTicketCount[msg.sender] += amount;

        emit TicketPurchased(msg.sender, currentLotteryId, amount);
    }

    function initiateDraw() external nonReentrant {
        if (block.timestamp < lotteryEndTime) revert LotteryNotEnded();
        if (lotteryParticipants[currentLotteryId].length == 0) revert NoParticipants();
        if (drawInProgress) revert DrawInProgress();
        
        drawInProgress = true;
        
        // Request random number from Gelato VRF
        bytes memory data = abi.encode(currentLotteryId, totalPool);
        _requestRandomness(data);
        
        emit DrawInitiated(currentLotteryId);
    }

    function _fulfillRandomness(
        uint256 randomness,
        uint256 requestId,
        bytes memory extraData
    ) internal override {
        (uint256 lotteryId, uint256 prizePool) = abi.decode(extraData, (uint256, uint256));
        
        // Select winner
        uint256 participantCount = lotteryParticipants[lotteryId].length;
        uint256 winnerIndex = randomness % participantCount;
        address winner = lotteryParticipants[lotteryId][winnerIndex];
        
        // Calculate prizes
        uint256 winnerFee = (prizePool * WINNER_FEE) / FEE_DENOMINATOR;
        uint256 winnerPrize = prizePool - winnerFee;

        // Transfer prize to winner
        paymentToken.safeTransfer(winner, winnerPrize);

        // Add winner fee as incentive
        paymentToken.approve(address(berachainVault), winnerFee);
        berachainVault.addIncentive(address(paymentToken), winnerFee, 0);

        // Record results
        lotteryWinners[lotteryId] = winner;
        lotteryPrizes[lotteryId] = winnerPrize;

        emit LotteryWinner(winner, winnerPrize);
        emit IncentiveAdded(winnerFee);

        // Reset for next lottery
        totalPool = 0;
        currentLotteryId += 1;
        lotteryEndTime = block.timestamp + 1 days;
        drawInProgress = false;

        // Reset ticket counts
        for (uint256 i = 0; i < participantCount; i++) {
            address participant = lotteryParticipants[lotteryId][i];
            userTicketCount[participant] = 0;
        }
    }

    // View functions
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

    function _operator() internal view virtual override returns (address) {
        return 0xB38D2cF1024731d4cAcD8ED70BDa77aC93022911; // Replace with actual operator
    }
} 