// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";

contract Skills is UniversalData {
    uint256 private skillIndex;
    uint256 private skillGroupIndex;

    struct Skill {
        bool dependency;
        bool disabled;
        Stat primary_attribute;
        Stat secondary_attribute;
        string icon;
        string name;
        uint256 dependency_id;
        uint256 group_id;
        uint256 id;
        uint256 multiplier;
        uint256[5] bonus_per_level;
    }

    mapping(uint256 => Skill) internal skillById;

    struct SkillGroup {
        bool disabled;
        uint256 id;
        string name;
    }
    mapping(uint256 => SkillGroup) internal skillGroupById;
    mapping(uint256 => Skill[]) internal skillsByGroupId;

    constructor(address _gameManager) UniversalData(_gameManager) {}

    function addSkill(Skill memory _skill) public onlyAdmin {
        _skill.id = skillIndex;
        _skill.disabled = false;
        skillById[skillIndex] = _skill;
        skillIndex += 1;
    }

    function addSkillGroup(SkillGroup memory _skillGroup) public onlyAdmin {
        _skillGroup.id = skillGroupIndex;
        _skillGroup.disabled = false;
        skillGroupById[skillGroupIndex] = _skillGroup;
        skillGroupIndex += 1;
    }

    function disableSkill(uint256 _skillId) public onlyAdmin {
        skillById[_skillId].disabled = true;
    }

    function disableSkillGroup(uint256 _skillGroupId) public onlyAdmin {
        skillGroupById[_skillGroupId].disabled = true;
    }

    function enableSkill(uint256 _skillId) public onlyAdmin {
        skillById[_skillId].disabled = false;
    }

    function enableSkillGroup(uint256 _skillGroupId) public onlyAdmin {
        skillGroupById[_skillGroupId].disabled = false;
    }

    function getSkillById(uint256 _skillId) public view returns (Skill memory) {
        return skillById[_skillId];
    }

    function getSkillsByGroupId(uint256 _skillGroupId)
        public
        view
        returns (Skill[] memory skills)
    {
        return skillsByGroupId[_skillGroupId];
    }

    function getStatName(Stat _stat) public pure returns (string memory) {
        if (_stat == Stat.charisma) {
            return "Charisma";
        }

        if (_stat == Stat.ingenuity) {
            return "Ingenuity";
        }

        if (_stat == Stat.intelligence) {
            return "Intelligence";
        }

        if (_stat == Stat.spirit) {
            return "Spirit";
        }

        if (_stat == Stat.toughness) {
            return "Toughness";
        }

        return "";
    }
}
