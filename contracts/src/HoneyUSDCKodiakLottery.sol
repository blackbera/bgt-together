// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BGTTogetherVault } from "./BGTTogetherVault.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract HoneyUSDCKodiakLottery is BGTTogetherVault {
    address public constant HONEY_USDC = 0xb73deE52F38539bA854979eab6342A60dD4C8c03;

    constructor(
        address _rewardsVault
    ) BGTTogetherVault(
        HONEY_USDC,
        _rewardsVault,
        "przHONEYUSDC",
        "przHUSDC"
    ) {}

    function deposit(uint256 amount) external returns (uint256 shares) {
        IERC20(HONEY_USDC).transferFrom(msg.sender, address(this), amount);
        shares = depositReceiptTokens(amount);
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 amount) external returns (uint256 shares) {
        shares = withdrawReceiptTokens(amount);
        IERC20(HONEY_USDC).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, shares);
    }

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
} 