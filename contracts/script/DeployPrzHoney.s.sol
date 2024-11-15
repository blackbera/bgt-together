// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {PrzHoney} from "../src/PrzHoney.sol";

contract DeployPrzHoney is Script {
    address constant LOTTERY_VAULT = 0x92145d189B44c8F60d0a60132b8880f1A7FBb232;

    function run() external returns (PrzHoney) {
        // Get deployer's private key from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy PrzHoney
        PrzHoney przHoney = new PrzHoney(LOTTERY_VAULT);

        vm.stopBroadcast();
        return przHoney;
    }
} 