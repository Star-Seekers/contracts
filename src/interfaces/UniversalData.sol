// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "../GameManager.sol";
import "../interfaces/ICloningFacility.sol";
import "../interfaces/ILearning.sol";

contract UniversalData {
    GameManager internal gameManager;

    modifier notInMaintenance() virtual {
        require(
            gameManager.maintenance() == false,
            "Star Seekers: Down for Maintenance"
        );
        _;
    }
    modifier onlyGameContract() virtual {
        require(
            gameManager.isGameContract(msg.sender),
            "Star Seekers: Not a game contract"
        );
        _;
    }
    modifier onlyAdmin() virtual {
        require(msg.sender == gameManager.admin(), "Star Seekers: Admin only");
        _;
    }

    modifier onlyCloneOwner(address _owner, uint256 _cloneId) virtual {
        ICloningFacility cloningFacility = ICloningFacility(
            payable(gameManager.contractAddresses("CloningFacility"))
        );
        ICloningFacility.CloneData memory cloneData = cloningFacility
            .getCloneData(_cloneId);

        require(cloneData.owner == _owner, "Star Seekers: Clone owner only");
        _;
    }

    modifier notForSale(uint256 _cloneId) virtual {
        ICloningFacility cloningFacility = ICloningFacility(
            gameManager.contractAddresses("CloningFacility")
        );
        ICloningFacility.CloneData memory cloneData = cloningFacility
            .getCloneData(_cloneId);

        require(
            cloneData.for_sale == false,
            "Star Seekers: Can't complete action while clone is for sale"
        );
        _;
    }
}
