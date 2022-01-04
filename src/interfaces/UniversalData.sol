// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "../GameManager.sol";
import "../Clones.sol";

contract UniversalData {
    GameManager internal gameManager;

    enum Stat {
        charisma,
        ingenuity,
        intelligence,
        spirit,
        toughness
    }

    modifier notInMaintenance() {
        require(
            !gameManager.maintenance(),
            "Star Seekers: Down for Maintenance"
        );
        _;
    }
    modifier onlyGameManager() {
        require(
            address(gameManager) == msg.sender,
            "Star Seekers: Only game manager"
        );
        _;
    }
    modifier onlyGameContract() {
        require(
            gameManager.isGameContract(msg.sender),
            "Star Seekers: Not a game contract"
        );
        _;
    }
    modifier onlyAdmin() {
        require(msg.sender == gameManager.admin(), "Star Seekers: Admin only");
        _;
    }
    modifier onlyCloneOwner(address _owner, uint256 _cloneId) {
        Clones clonesInstance = Clones(gameManager.contractAddresses("Clones"));
        (address owner, , ) = clonesInstance.cloneData(_cloneId);

        require(owner == _owner, "Star Seekers: Clone owner only");
        _;
    }

    constructor(address _gameManager) {
        gameManager = GameManager(_gameManager);
    }
}
