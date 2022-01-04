// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./GameManager.sol";

import "./interfaces/UniversalData.sol";

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
        Stat bonus_stat;
        Stat penalty_stat;
    }
    mapping(uint256 => Implant) internal implantById;
    mapping(uint256 => bool) internal disabledImplants;

    constructor(address _gameManager) UniversalData(_gameManager) {}

    function addImplant(Implant memory _implant) public onlyAdmin {
        _implant.id = implantIndex;
        _implant.disabled = false;
        implantById[implantIndex] = _implant;
        implantIndex += 1;
    }

    function disableImplant(uint256 _implantId) public onlyAdmin {
        implantById[_implantId].disabled = true;
        disabledImplants[_implantId] = true;
    }

    function enableImplant(uint256 _implantId) public onlyAdmin {
        implantById[_implantId].disabled = false;
        disabledImplants[_implantId] = false;
    }

    function getImplantById(uint256 _implantId)
        public
        view
        returns (Implant memory)
    {
        return implantById[_implantId];
    }
}
