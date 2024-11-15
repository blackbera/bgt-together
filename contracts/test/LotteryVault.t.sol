// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// =================
// === IMPORTS ====
// =================
import { Test } from "forge-std/Test.sol";
import { LotteryVault } from "../src/LotteryVault.sol";
import { PrzHoney } from "../src/PrzHoney.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IBerachainRewardsVault } from "contracts-monorepo/pol/interfaces/IBerachainRewardsVault.sol";
import { BerachainGovernance } from "contracts-monorepo/gov/BerachainGovernance.sol";

/* 
- Add governance setups to be able to test the reward vault
- Get przHoney test working to make sure that the lottery system is working 
*/

// =================
// === INTERFACES ====
// =================
interface IHoney is IERC20 {
    function factory() external view returns (address);
    function mint(address to, uint256 amount) external;
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

    // =================
    // === CONSTANTS ====
    // =================
    // Berachain Addresses
    address public constant HONEY = 0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03;
    address public constant HONEY_FACTORY = 0xAd1782b2a7020631249031618fB1Bd09CD926b31;
    address public constant OPERATOR = 0x98F43E30A80af84cbC55599392A16983f832CEB3;
    address public constant HONEY_WHALE = 0xCe67E15cbCb3486B29aD44486c5B5d32f361fdDc;
    address public constant REWARDS_VAULT_FACTORY = 0x2B6e40f65D82A0cB98795bC7587a71bfa49fBB2B;
    address public constant GOV = 0xE3EDa03401Cf32010a9A9967DaBAEe47ed0E1a0b;
    address public constant BERACHEF = 0xfb81E39E3970076ab2693fA5C45A07Cc724C93c2;

    // Time Constants
    uint256 internal constant MIN_DELAY_TIMELOCK = 2 days;
    
    // Test Addresses
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");

    // Lottery Constants
    uint256 public constant TICKET_PRICE = 1 ether;  
    uint256 public constant LOTTERY_DURATION = 1 days;
    uint256 public constant INITIAL_BALANCE = 10 ether; 

    // =================
    // === SETUP ====
    // =================
    function setUp() public {
        // Fork Setup
        vm.createSelectFork("https://bartio.rpc.berachain.com/");

        // Contract Deployments
        paymentToken = IHoney(HONEY);
        przHoney = new PrzHoney(owner);

        // Rewards Vault Setup
        IBerachainRewardsVaultFactory factory = IBerachainRewardsVaultFactory(REWARDS_VAULT_FACTORY);
        address vaultAddress = factory.createRewardsVault(address(przHoney));
        rewardsVault = IBerachainRewardsVault(vaultAddress);
        _setupRewardsVaultAndIncentives();

        // Lottery Vault Setup
        lotteryVault = new LotteryVault(
            address(paymentToken),
            owner,
            address(rewardsVault)
        );

        vm.prank(owner);
        lotteryVault.setPrzHoney(address(przHoney));

        // PrzHoney Configuration
        vm.prank(owner);
        przHoney.setMinter(address(lotteryVault));

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
    }
    // =================
    // === GOVERNANCE HELPERS ====
    // =================
    function _setupRewardsVaultAndIncentives() internal {
        address[] memory targets = new address[](2);
        targets[0] = BERACHEF;
        targets[1] = address(rewardsVault);
        
        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = abi.encodeCall(IBeraChef.setFriend, (address(rewardsVault), true));
        calldatas[1] = abi.encodeCall(IBerachainRewardsVault.whitelistIncentiveToken, (HONEY, true));

        _createProposalAndExecute(
            targets,
            calldatas,
            "Setup rewards vault permissions"
        );
    }
    function _createProposalAndExecute(
        address[] memory targets,
        bytes[] memory calldatas,
        string memory description
    ) internal returns (uint256) {
        uint256[] memory values = new uint256[](targets.length);
        
        // Create proposal
        uint256 proposalId = gov.propose(targets, values, calldatas, description);
        
        // Wait for voting delay
        vm.roll(gov.proposalSnapshot(proposalId) + 1);
        
        // Vote
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
    function test_PrzHoneyIntegration() public {
        vm.prank(owner);
        lotteryVault.startLottery();

        vm.prank(user1);
        lotteryVault.purchaseTicket(1);

        // Check PrzHoney was minted
        assertEq(przHoney.balanceOf(user1), 1);

        // Complete lottery
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);
        lotteryVault.initiateDraw();

        assertEq(przHoney.balanceOf(user1), 0);
    }

    function test_RewardsVaultIntegration() public {
        vm.prank(owner);
        lotteryVault.startLottery();

        vm.prank(user1);
        lotteryVault.purchaseTicket(1);

        // Check stake in rewards vault
        assertEq(rewardsVault.balanceOf(user1), 1);

        // Complete lottery
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);
        lotteryVault.initiateDraw();
        
        // Check stake was withdrawn
        assertEq(rewardsVault.balanceOf(user1), 0);
    }
}