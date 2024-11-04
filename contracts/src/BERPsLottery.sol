// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { BGTTogetherVault } from "./BGTTogetherVault.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract BERPsLottery is BGTTogetherVault {
    address public constant BERPS = 0x1306D3c36eC7E38dd2c128fBe3097C2C2449af64;

    constructor(
        address _rewardsVault,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionId
    ) BGTTogetherVault(
        BERPS,
        _rewardsVault,
        _vrfCoordinator,
        _keyHash,
        _subscriptionId,
        "BERPs Lottery",
        "BERPs-LT"
    ) {}

    function deposit(uint256 amount) external returns (uint256 shares) {
        IERC20(BERPS).transferFrom(msg.sender, address(this), amount);
        shares = depositReceiptTokens(amount);
        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 amount) external returns (uint256 shares) {
        shares = withdrawReceiptTokens(amount);
        IERC20(BERPS).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount, shares);
    }

    event Deposit(address indexed user, uint256 amount, uint256 shares);
    event Withdraw(address indexed user, uint256 amount, uint256 shares);
} 