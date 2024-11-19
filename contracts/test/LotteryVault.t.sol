// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// =================
// === IMPORTS ====
// =================
import { Test } from "forge-std/Test.sol";
import { LotteryVault } from "../src/LotteryVault.sol";
import { PrzHoney } from "../src/PrzHoney.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBerachainRewardsVault } from "contracts-monorepo/pol/interfaces/IBerachainRewardsVault.sol";
import { BerachainGovernance } from "contracts-monorepo/gov/BerachainGovernance.sol";
import { IBerachainRewardsVaultFactory } from "contracts-monorepo/pol/interfaces/IBerachainRewardsVaultFactory.sol";
import { BerachainRewardsVault } from "contracts-monorepo/pol/rewards/BerachainRewardsVault.sol";
import { IBeraChef } from "contracts-monorepo/pol/interfaces/IBeraChef.sol";
import { BerachainRewardsVaultFactory } from "contracts-monorepo/pol/rewards/BerachainRewardsVaultFactory.sol";
import {console} from "forge-std/console.sol";

// =================
// === INTERFACES ====
// =================
interface IHoney is IERC20 {
    function factory() external view returns (address);
    function mint(address to, uint256 amount) external;
}

interface IBerachainGovernance {
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256);
}

contract LotteryVaultTest is Test {
    // =================
    // === STATE VARIABLES ====
    // =================
    LotteryVault public lotteryVault;
    IERC20 public paymentToken;     
    PrzHoney public przHoney;
    IBerachainRewardsVault public rewardsVault;
    BerachainGovernance public gov;
    BerachainRewardsVaultFactory internal factory;
    // =================
    // === CONSTANTS ====
    // =================
    // Berachain Addresses
    address public constant HONEY = 0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03;
    address public constant HONEY_FACTORY = 0xAd1782b2a7020631249031618fB1Bd09CD926b31;
    address public constant HONEY_WHALE = 0xCe67E15cbCb3486B29aD44486c5B5d32f361fdDc;
    address public constant REWARDS_VAULT_FACTORY = 0x2B6e40f65D82A0cB98795bC7587a71bfa49fBB2B;
    address public constant GOV = 0xE3EDa03401Cf32010a9A9967DaBAEe47ed0E1a0b;
    address public constant BERACHEF = 0xfb81E39E3970076ab2693fA5C45A07Cc724C93c2;

    event RequestedRandomness(uint256 round, bytes data);

    // Time Constants
    uint256 internal constant MIN_DELAY_TIMELOCK = 2 days;
    
    // Test Addresses
    address public operator = makeAddr("operator");
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    // Lottery Constants
    uint256 public constant TICKET_PRICE = 1 ether;  
    uint256 public constant LOTTERY_DURATION = 1 days;
    uint256 public constant INITIAL_BALANCE = 10 ether; 

    address public constant LOTTERY_VAULT = 0x6e4db4506ba3f763cA4dFaFE77bA6F1e606B86f0;
    address public constant PRZ_HONEY = 0xa3f04C07A4941A5860B9367254a072Fb17515993;
    address public constant REWARDS_VAULT = 0x677f6e28428784a0471C7f0775B030973F296568;
    address public constant FACTORY = 0x2B6e40f65D82A0cB98795bC7587a71bfa49fBB2B;

    // =================
    // === SETUP ====
    // =================
    function setUp() public {
        // Fork Setup
        vm.createSelectFork("https://bartio.rpc.berachain.com/");

        // Contract Deployments
        paymentToken = IHoney(HONEY);
        przHoney = new PrzHoney(owner);

        gov = BerachainGovernance(payable(GOV));

        // Rewards Vault Setup
        factory = BerachainRewardsVaultFactory(REWARDS_VAULT_FACTORY);
        address vaultAddress = factory.createRewardsVault(address(przHoney));
        rewardsVault = IBerachainRewardsVault(vaultAddress);

        _setupRewardsVaultAndIncentives();

        // Lottery Vault Setup
        vm.deal(address(owner), 100 ether); 
        vm.prank(owner);
        lotteryVault = new LotteryVault(
            address(paymentToken),
            owner,
            address(rewardsVault),
            operator
        );

        // Owner sends ETH to lottery vault
        vm.prank(owner);
        (bool success,) = address(lotteryVault).call{value: 10 ether}("");
        require(success, "ETH transfer failed");
    

        vm.deal(address(lotteryVault), 10 ether);

        vm.prank(owner);
        lotteryVault.setPrzHoney(address(przHoney));

        // PrzHoney Configuration
        vm.prank(owner);
        przHoney.transferOwnership(address(lotteryVault));

        // Initial Token Distribution
        vm.startPrank(HONEY_WHALE);
        IERC20(HONEY).transfer(user1, INITIAL_BALANCE);
        IERC20(HONEY).transfer(user2, INITIAL_BALANCE);
        IERC20(HONEY).transfer(user3, INITIAL_BALANCE);
        vm.stopPrank();

        // Token Approvals
        vm.startPrank(user1);
        paymentToken.approve(address(lotteryVault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        paymentToken.approve(address(lotteryVault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user3);
        paymentToken.approve(address(lotteryVault), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user1);
        przHoney.approve(address(rewardsVault), type(uint256).max); 
        vm.stopPrank();
    }
    // =================
    // === GOVERNANCE HELPERS ====
    // =================
    function _setupRewardsVaultAndIncentives() internal {
        address[] memory targets = new address[](1);
        targets[0] = BERACHEF;
        
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSelector(IBeraChef.updateFriendsOfTheChef.selector, address(rewardsVault), true);

        _createProposalAndExecute(
            targets,
            calldatas,
            "Setup rewards vault permissions"
        );

        // Timelock contract whitelisting incentive token on our new vault
        vm.prank(0xcB364028856f2328148Bb32f9D6E7a1F86451b1c);
        rewardsVault.whitelistIncentiveToken(
            HONEY,
            1
        );
    }
    function _createProposalAndExecute(
        address[] memory targets,
        bytes[] memory calldatas,
        string memory description
    ) internal returns (uint256) {
        uint256[] memory values = new uint256[](targets.length);
        
        // Create proposal
        vm.prank(HONEY_WHALE);
        uint256 proposalId = gov.propose(targets, values, calldatas, description);
        
        // Wait for voting delay
        vm.roll(gov.proposalSnapshot(proposalId) + 1);
        
        // Vote
        vm.prank(HONEY_WHALE);
        gov.castVote(proposalId, 1); // Vote in favor
        
        // Wait for voting period to end
        vm.roll(gov.proposalDeadline(proposalId) + 1);
        
        // Queue
        gov.queue(proposalId);
        
        // Wait for timelock
        vm.warp(block.timestamp + MIN_DELAY_TIMELOCK + 1);
        
        // Execute
        gov.execute(proposalId);

        return proposalId;
    }

    // =================
    // === TESTS ====
    // =================
    function test_PurchaseTicket() public {
        vm.prank(owner);
        lotteryVault.startLottery();

        vm.prank(user1);
        lotteryVault.purchaseTicket(1);

        // Complete lottery
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);
        lotteryVault.initiateDraw();

        (, , uint256 amountRemaining) = BerachainRewardsVault(address(rewardsVault)).incentives(HONEY);
        console.log("Amount remaining of honey incentive: ", amountRemaining);
        assertTrue(amountRemaining > 0, "Should have incentives remaining");
    }

    function test_CannotStartMultipleLotteries() public {
    vm.prank(owner);
    lotteryVault.startLottery();
    
    vm.prank(owner);
    vm.expectRevert(LotteryVault.LotteryAlreadyActive.selector);
    lotteryVault.startLottery();
}

    function test_VRFIntegration() public {
        // Start lottery
        vm.prank(owner);
        lotteryVault.startLottery();

        // Users buy tickets
        vm.prank(user1);
        lotteryVault.purchaseTicket(1);
        vm.prank(user2);
        lotteryVault.purchaseTicket(2);

        // Fast forward to end
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);

        // Expected VRF Request event data
        uint256 roundId = 4553143; // From the trace logs
        bytes memory data = abi.encode(1, lotteryVault.totalPool()); // lotteryId and total pool
        bytes memory dataWithRequest = abi.encode(0, data); // requestId and data

        // Expect the VRF request event
        vm.expectEmit(true, true, false, false);
        emit RequestedRandomness(roundId, dataWithRequest);

        // Initiate draw
        lotteryVault.initiateDraw();

        // Test non-operator cannot fulfill
        vm.prank(user1);
        vm.expectRevert("only operator");
        lotteryVault.fulfillRandomness(123, dataWithRequest);

        // Test operator can fulfill
        uint256 randomness = 0x670c890348fbf2618741e87223634bf817898cfa3cb2ee0d409c5e923d10f407;
        vm.prank(operator);
        lotteryVault.fulfillRandomness(randomness, dataWithRequest);

        // Verify lottery state after fulfillment
        assertFalse(lotteryVault.lotteryActive(), "Lottery should be inactive");
        assertFalse(lotteryVault.drawInProgress(), "Draw should not be in progress");

        // Verify winner was selected and prize was set
        address winner = lotteryVault.lotteryWinners(1);
        assertTrue(winner == user1 || winner == user2, "Winner should be one of the participants");
        assertTrue(lotteryVault.lotteryPrizes(1) > 0, "Prize should be set");

        // Test replay protection
        vm.prank(operator);
        vm.expectRevert("request fulfilled or missing");
        lotteryVault.fulfillRandomness(randomness, dataWithRequest);
    }

}