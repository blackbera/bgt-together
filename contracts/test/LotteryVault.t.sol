// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { Test } from "forge-std/Test.sol";
import { LotteryVault } from "../src/LotteryVault.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IBerachainRewardsVault } from "contracts-monorepo/src/pol/interfaces/IBerachainRewardsVault.sol";
import { IBerachainRewardsVaultFactory } from "contracts-monorepo/src/pol/interfaces/IBerachainRewardsVaultFactory.sol";
import { BerachainGovernance } from "contracts-monorepo/src/gov/BerachainGovernance.sol";
import { IBGT } from "contracts-monorepo/src/pol/interfaces/IBGT.sol";
import { IBeraChef } from "contracts-monorepo/src/pol/interfaces/IBeraChef.sol";

contract LotteryVaultTest is Test {
    LotteryVault public lotteryVault;
    IERC20 public paymentToken;      // HONEY
    IBGT public bgt;                 // BGT
    IBerachainRewardsVault public rewardsVault;
    IBerachainRewardsVaultFactory public vaultFactory;
    BerachainGovernance public gov;

    address public constant GOVERNANCE = 0xE3EDa03401Cf32010a9A9967DaBAEe47ed0E1a0b;
    address public constant BLOCK_REWARD_CONTROLLER = 0x696C296D320beF7b3148420bf2Ff4a378c0a209B;
    address public constant HONEY = address(0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03); 
    address public constant BGT = address(0xbDa130737BDd9618301681329bF2e46A016ff9Ad);   
    address public constant VAULT_FACTORY = address(0x2B6e40f65D82A0cB98795bC7587a71bfa49fBB2B);
    address public constant BERA_CHEF = 0x7D5a9B386EA9c0B91C9c0D8Fb277d8656c3E5E9e;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    address public user3 = address(4);

    uint256 public constant TICKET_PRICE = 100e18;
    uint256 public constant LOTTERY_DURATION = 1 days;
    uint256 public constant INITIAL_BALANCE = 1000e18;
    uint256 public constant VOTING_DELAY = 1;
    uint256 public constant VOTING_PERIOD = 50400; // About 7 days
    uint8 public constant VOTE_IN_FAVOUR = 1;

    function setUp() public {
        // Fork Berachain
        vm.createSelectFork(vm.envString("https://bartio.rpc.berachain.com/"));

        gov = BerachainGovernance(GOVERNANCE);
        bgt = IBGT(BGT);
        paymentToken = IERC20(HONEY);
        vaultFactory = IBerachainRewardsVaultFactory(VAULT_FACTORY);

        vm.startPrank(BLOCK_REWARD_CONTROLLER);
        bgt.mint(owner, 3_000_000_000e18); // 3B BGT
        vm.stopPrank();

        vm.startPrank(owner);
        bgt.delegate(owner);

        // Deploy rewards vault first
        rewardsVault = IBerachainRewardsVault(
            vaultFactory.deployVault(
                BGT,
                "Lottery Rewards Vault",
                "LRV",
                7 days,
                owner
            )
        );

        // Create proposal for both operations (BeraChef first, then whitelist)
        address[] memory targets = new address[](2);
        targets[0] = BERA_CHEF;              // BeraChef call first
        targets[1] = address(rewardsVault);   // Whitelist call second
        
        uint256[] memory values = new uint256[](2);
        values[0] = 0;
        values[1] = 0;
        
        bytes[] memory calldatas = new bytes[](2);
        calldatas[0] = abi.encodeCall(
            IBeraChef.updateFriendsOfTheChef,
            (address(rewardsVault), true)
        );
        calldatas[1] = abi.encodeCall(
            IBerachainRewardsVault.whitelistIncentiveToken,
            (HONEY, 0, owner)
        );

        string memory description = "Make vault friend of chef and whitelist HONEY";
        uint256 proposalId = gov.propose(
            targets,
            values,
            calldatas,
            description
        );

        // Wait for voting delay
        vm.roll(block.number + VOTING_DELAY + 1);

        // Vote
        gov.castVote(proposalId, VOTE_IN_FAVOUR);

        // Wait for voting period to end
        vm.roll(block.number + VOTING_PERIOD + 1);

        // Queue and execute
        bytes32 descHash = keccak256(bytes(description));
        gov.queue(targets, values, calldatas, descHash);
        vm.warp(block.timestamp + gov.getMinDelay() + 1);
        gov.execute(targets, values, calldatas, descHash);

        // Deploy lottery vault
        lotteryVault = new LotteryVault(
            HONEY,
            BGT,
            address(rewardsVault)
        );

        vm.stopPrank();

        // Setup test users
        deal(HONEY, user1, INITIAL_BALANCE);
        deal(HONEY, user2, INITIAL_BALANCE);
        deal(HONEY, user3, INITIAL_BALANCE);

        vm.prank(user1);
        paymentToken.approve(address(lotteryVault), type(uint256).max);
        vm.prank(user2);
        paymentToken.approve(address(lotteryVault), type(uint256).max);
        vm.prank(user3);
        paymentToken.approve(address(lotteryVault), type(uint256).max);
    }

    function test_StartLottery() public {
        vm.prank(owner);
        
        vm.expectEmit(true, true, true, true);
        emit LotteryStarted(1, TICKET_PRICE, block.timestamp + LOTTERY_DURATION);
        
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);
        
        assertTrue(lotteryVault.lotteryActive());
        assertEq(lotteryVault.ticketPrice(), TICKET_PRICE);
        assertEq(lotteryVault.lotteryEndTime(), block.timestamp + LOTTERY_DURATION);
    }

    function test_StartLottery_RevertIfNotOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);
    }

    function test_PurchaseTicket() public {
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);

        vm.prank(user1);
        vm.expectEmit(true, true, true, true);
        emit TicketPurchased(user1, 1, 1);
        lotteryVault.purchaseTicket(1);

        assertEq(lotteryVault.userTicketCount(user1), 1);
        
        address[] memory participants = lotteryVault.getCurrentParticipants();
        assertEq(participants.length, 1);
        assertEq(participants[0], user1);
    }

    function test_PurchaseMultipleTickets() public {
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);

        vm.prank(user1);
        lotteryVault.purchaseTicket(3);

        assertEq(lotteryVault.userTicketCount(user1), 3);
        
        // Check that user appears 3 times in participants array
        address[] memory participants = lotteryVault.getCurrentParticipants();
        assertEq(participants.length, 3);
        for(uint i = 0; i < 3; i++) {
            assertEq(participants[i], user1);
        }
    }

    function test_PurchaseTicket_RevertIfNoActiveLottery() public {
        vm.prank(user1);
        vm.expectRevert(NoActiveLottery.selector);
        lotteryVault.purchaseTicket(1);
    }

    function test_PurchaseTicket_RevertIfLotteryEnded() public {
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);
        
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);
        
        vm.prank(user1);
        vm.expectRevert(LotteryEnded.selector);
        lotteryVault.purchaseTicket(1);
    }

    function test_CompleteLotteryFlow() public {
        // Start lottery
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);

        // Multiple users buy tickets
        vm.prank(user1);
        lotteryVault.purchaseTicket(2);
        
        vm.prank(user2);
        lotteryVault.purchaseTicket(3);
        
        vm.prank(user3);
        lotteryVault.purchaseTicket(1);

        // Move time forward to end lottery
        vm.warp(block.timestamp + LOTTERY_DURATION + 1);

        // Initiate draw
        vm.expectEmit(true, true, true, true);
        emit DrawInitiated(1);
        lotteryVault.initiateDraw();

        // Simulate VRF callback with random number
        // We'll use a specific number to test a known winner
        uint256 randomness = 3; // This will select the 4th participant
        bytes memory extraData = abi.encode(1, lotteryVault.totalPool());
        
        vm.prank(lotteryVault._operator());
        lotteryVault._fulfillRandomness(randomness, 0, extraData);

        // Get lottery info
        (address winner, uint256 prize, address[] memory participants) = lotteryVault.getLotteryInfo(1);
        
        // Verify winner and prize
        assertTrue(winner == user1 || winner == user2 || winner == user3);
        assertTrue(prize > 0);
        assertEq(participants.length, 6); // Total tickets purchased

        // Verify new lottery is ready
        assertEq(lotteryVault.currentLotteryId(), 2);
        assertFalse(lotteryVault.drawInProgress());
        
        // Verify ticket counts were reset
        assertEq(lotteryVault.userTicketCount(user1), 0);
        assertEq(lotteryVault.userTicketCount(user2), 0);
        assertEq(lotteryVault.userTicketCount(user3), 0);
    }

    function test_InitiateDraw_RevertIfNotEnded() public {
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);

        vm.prank(user1);
        lotteryVault.purchaseTicket(1);

        vm.expectRevert(LotteryNotEnded.selector);
        lotteryVault.initiateDraw();
    }

    function test_InitiateDraw_RevertIfNoParticipants() public {
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);

        vm.warp(block.timestamp + LOTTERY_DURATION + 1);

        vm.expectRevert(NoParticipants.selector);
        lotteryVault.initiateDraw();
    }

    function test_GetTimeRemaining() public {
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);

        assertEq(lotteryVault.getTimeRemaining(), LOTTERY_DURATION);

        vm.warp(block.timestamp + LOTTERY_DURATION / 2);
        assertEq(lotteryVault.getTimeRemaining(), LOTTERY_DURATION / 2);

        vm.warp(block.timestamp + LOTTERY_DURATION);
        assertEq(lotteryVault.getTimeRemaining(), 0);
    }

    function test_Fees() public {
        vm.prank(owner);
        lotteryVault.startLottery(TICKET_PRICE, LOTTERY_DURATION);

        uint256 initialBalance = paymentToken.balanceOf(user1);
        
        vm.prank(user1);
        lotteryVault.purchaseTicket(1);

        uint256 purchaseFee = (TICKET_PRICE * 100) / 10000; // 1% purchase fee
        uint256 expectedBalance = initialBalance - TICKET_PRICE;
        
        assertEq(paymentToken.balanceOf(user1), expectedBalance);
        assertEq(lotteryVault.totalPool(), TICKET_PRICE - purchaseFee);
    }
} 