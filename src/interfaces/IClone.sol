// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

interface IClone {
    function create(address owner, string memory uri)
        external
        returns (uint256);
}
