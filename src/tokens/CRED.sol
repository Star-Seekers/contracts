// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/UniversalData.sol";

contract Cred is ERC20, UniversalData {
    /// @notice Emitted when credits are earned in game by a player
    event CreditsEarned(address player, uint256 amount);
    /// @notice Emitted when credits are spent in game by a player
    event CreditsSpent(address palyer, uint256 amount);

    constructor(address _gameManager)
        ERC20("Star Seekers", "CRED")
        UniversalData(_gameManager)
    {}

    /// @notice Creates new CRED tokens
    /// @dev can only be called by other game contracts
    function mint(address _to, uint256 _amount) external onlyGameContract {
        _mint(_to, _amount);

        emit CreditsEarned(_to, _amount);
    }

    /// @notice Spends existing CRED tokens
    /// @dev can only be called by other game contracts
    /// @dev burns the tokens by sending them to the 0 address.
    function spend(address _account, uint256 _amount)
        external
        onlyGameContract
    {
        _burn(_account, _amount);

        emit CreditsSpent(_account, _amount);
    }
}
