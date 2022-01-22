// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICred is IERC20 {
    function mint(address to, uint256 amount) external;

    function spend(address account, uint256 amount) external;
}
