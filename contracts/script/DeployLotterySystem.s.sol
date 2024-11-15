// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {LotteryVault} from "../src/LotteryVault.sol";
import {PrzHoney} from "../src/PrzHoney.sol";
import {console} from "forge-std/console.sol";

contract DeployLotterySystem is Script {
    // Berachain HONEY token address
    address constant HONEY = 0x0E4aaF1351de4c0264C5c7056Ef3777b41BD8e03;
    address constant REWARDS_VAULT = 0x1Bf16ec2113E65B6491d2e662Ad745fDf55DE09A;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy LotteryVault first
        LotteryVault lotteryVault = new LotteryVault{value: 5 ether}(
            HONEY,
            vm.addr(deployerPrivateKey), // owner
            REWARDS_VAULT
        );
        console.log("LotteryVault deployed at:", address(lotteryVault));

        // 2. Deploy PrzHoney with LotteryVault as owner
        PrzHoney przHoney = new PrzHoney(address(lotteryVault));
        console.log("PrzHoney deployed at:", address(przHoney));

        // 3. Set PrzHoney in LotteryVault
        lotteryVault.setPrzHoney(address(przHoney));
        console.log("PrzHoney set in LotteryVault");

        vm.stopBroadcast();

        // Log final setup
        console.log("\nFinal Setup:");
        console.log("------------");
        console.log("LotteryVault:", address(lotteryVault));
        console.log("PrzHoney:", address(przHoney));
        console.log("Owner:", vm.addr(deployerPrivateKey));
    }
}