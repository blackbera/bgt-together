// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BGTTogetherVault } from "./BGTTogetherVault.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BendLottery is BGTTogetherVault {
    address public constant BEND = 0x1339503343be5626B40Ee3Aee12a4DF50Aa4C0B9;

    constructor(
        address _rewardsVault
    ) BGTTogetherVault(
        BEND,
        _rewardsVault,
        "przBEND",
        "przBEND"
    ) {}

    function deposit(uint256 amount) external returns (uint256 shares) {
        IERC20(BEND).transferFrom(msg.sender, address(this), amount);
        shares = depositReceiptTokens(amount);
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 amount) external returns (uint256 shares) {
        shares = withdrawReceiptTokens(amount);
        IERC20(BEND).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, shares);
    }

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
} 