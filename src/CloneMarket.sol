// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";

contract CloneMarket is UniversalData {
    constructor(address _gameManager) UniversalData(_gameManager) {}
}
