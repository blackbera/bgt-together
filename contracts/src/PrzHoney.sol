// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract PrzHoney is ERC20, Ownable {
    error NotAuthorized();

    constructor(address _owner) ERC20("przHoney", "przHoney") Ownable(_owner) {}

    function mint(address to, uint256 amount) external {
        if (msg.sender != owner()) revert NotAuthorized();
        _mint(to, amount);
        _approve(to, msg.sender, type(uint256).max);
    }

    function burn(address from, uint256 amount) external {
        if (msg.sender != owner()) revert NotAuthorized();
        _burn(from, amount);
    }
} 