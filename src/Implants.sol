// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IStats.sol";

contract Implants is UniversalData {
    uint256 public implantIndex;

    struct Implant {
        bool disabled;
        uint256 id;
        uint256 bonus_amount;
        uint256 penalty_amount;
        string name;
        string description;
        string icon;
        IStats.Stat bonus_stat;
        IStats.Stat penalty_stat;
    }
    mapping(uint256 => Implant) internal implantById;

    event ImplantUpdated(uint256 _implantId);

    constructor(address _gameManager) UniversalData(_gameManager) {}

    function addImplant(Implant memory _implant) public onlyAdmin {
        _implant.id = implantIndex;
        _implant.disabled = false;
        implantById[implantIndex] = _implant;
        implantIndex += 1;

        emit ImplantUpdated(_implant.id);
    }

    function disableImplant(uint256 _implantId) public onlyAdmin {
        implantById[_implantId].disabled = true;

        emit ImplantUpdated(_implantId);
    }

    function enableImplant(uint256 _implantId) public onlyAdmin {
        implantById[_implantId].disabled = false;

        emit ImplantUpdated(_implantId);
    }

    function getImplantById(uint256 _implantId)
        internal
        view
        returns (Implant memory)
    {
        return implantById[_implantId];
    }
}
