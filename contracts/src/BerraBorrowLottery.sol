// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BGTTogetherVault } from "./BGTTogetherVault.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BerraBorrowLottery is BGTTogetherVault {
    address public constant BERRA_BORROW = 0x3a7f6f2F27f7794a7820a32313F4a68e36580864;

    constructor(
        address _rewardsVault,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) BGTTogetherVault(
        BERRA_BORROW,
        _rewardsVault,
        _vrfCoordinator,
        _keyHash,
        _subscriptionId,
        "BerraBorrow Lottery",
        "BERRA-B-LT"
    ) {}

    function deposit(uint256 amount) external returns (uint256 shares) {
        IERC20(BERRA_BORROW).transferFrom(msg.sender, address(this), amount);
        shares = depositReceiptTokens(amount);
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 amount) external returns (uint256 shares) {
        shares = withdrawReceiptTokens(amount);
        IERC20(BERRA_BORROW).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, shares);
    }

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
} 