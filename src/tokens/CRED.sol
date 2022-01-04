// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/UniversalData.sol";

contract CRED is ERC20, UniversalData {
    constructor(address _gameManager)
        ERC20("Star Seekers", "CRED")
        UniversalData(_gameManager)
    {}
}
