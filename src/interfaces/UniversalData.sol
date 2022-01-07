// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "../GameManager.sol";
import "../interfaces/IClones.sol";
import "../interfaces/ILearning.sol";

contract UniversalData {
    GameManager internal gameManager;

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
        IClones clonesInstance = IClones(
            gameManager.contractAddresses("Clones")
        );
        IClones.CloneData memory cloneData = clonesInstance.getCloneData(
            _cloneId
        );

        require(cloneData.owner == _owner, "Star Seekers: Clone owner only");
        _;
    }
    modifier notForSale(uint256 _cloneId) {
        IClones clonesInstance = IClones(
            gameManager.contractAddresses("Clones")
        );
        IClones.CloneData memory cloneData = clonesInstance.getCloneData(
            _cloneId
        );

        require(
            cloneData.for_sale == false,
            "Star Seekers: Can't complete action while clone is for sale"
        );
        _;
    }

    constructor(address _gameManager) {
        gameManager = GameManager(_gameManager);
    }
}
