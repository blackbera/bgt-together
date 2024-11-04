// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BGTTogetherVault } from "./BGTTogetherVault.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract YeetKodiakLottery is BGTTogetherVault {
    address public constant YEET_KODIAK = 0xE5A2ab5D2fb268E5fF43A5564e44c3309609aFF9;

    constructor(
        address _rewardsVault,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) BGTTogetherVault(
        YEET_KODIAK,
        _rewardsVault,
        _vrfCoordinator,
        _keyHash,
        _subscriptionId,
        "Yeet-Kodiak Lottery",
        "YEET-K-LT"
    ) {}

    function deposit(uint256 amount) external returns (uint256 shares) {
        IERC20(YEET_KODIAK).transferFrom(msg.sender, address(this), amount);
        shares = depositReceiptTokens(amount);
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 amount) external returns (uint256 shares) {
        shares = withdrawReceiptTokens(amount);
        IERC20(YEET_KODIAK).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, shares);
    }

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
} 