// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BGTTogetherVault } from "./BGTTogetherVault.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract HoneyWBERALottery is BGTTogetherVault {
    address public constant BEX_LP = 0xd28d852cbcc68DCEC922f6d5C7a8185dBaa104B7;

    constructor(
        address _rewardsVault,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) BGTTogetherVault(
        BEX_LP,              // asset (LP token)
        _rewardsVault,       // BerachainRewardsVault
        _vrfCoordinator,     // Chainlink VRF
        _keyHash,            // VRF key hash
        _subscriptionId,     // VRF subscription ID
        "Honey WBERA Lottery", // vault name
        "hWBERA-LT"           // vault symbol
    ) {}

    function deposit(uint256 amount) external returns (uint256 shares) {
        IERC20(BEX_LP).transferFrom(msg.sender, address(this), amount);
        
        shares = depositReceiptTokens(amount);
        
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 amount) external returns (uint256 shares) {
        shares = withdrawReceiptTokens(amount);
        
        IERC20(BEX_LP).transfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount, shares);
    }

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
}
