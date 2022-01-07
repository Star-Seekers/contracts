// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface ICred {
    function mint(address to, uint256 amount) external;

    function spend(address account, uint256 amount) external;
}
