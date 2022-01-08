// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IStats.sol";

contract Skills is UniversalData {
    uint256 private skillIndex;
    uint256 private skillGroupIndex;

    struct Skill {
        bool dependency;
        bool disabled;
        IStats.Stat primary_attribute;
        IStats.Stat secondary_attribute;
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

    event SkillUpdated(uint256 skillId);
    event SkillGroupUpdated(uint256 skillGroupId);

    constructor(address _gameManager) UniversalData(_gameManager) {}

    function addSkill(Skill memory _skill) public onlyAdmin {
        _skill.id = skillIndex;
        _skill.disabled = false;
        skillById[skillIndex] = _skill;
        skillsByGroupId[_skill.group_id].push(_skill);
        skillIndex += 1;

        emit SkillUpdated(_skill.id);
    }

    function addSkillGroup(SkillGroup memory _skillGroup) public onlyAdmin {
        _skillGroup.id = skillGroupIndex;
        _skillGroup.disabled = false;
        skillGroupById[skillGroupIndex] = _skillGroup;
        skillGroupIndex += 1;

        emit SkillGroupUpdated(_skillGroup.id);
    }

    function disableSkill(uint256 _skillId) public onlyAdmin {
        skillById[_skillId].disabled = true;

        emit SkillUpdated(_skillId);
    }

    function disableSkillGroup(uint256 _skillGroupId) public onlyAdmin {
        skillGroupById[_skillGroupId].disabled = true;

        emit SkillGroupUpdated(_skillGroupId);
    }

    function enableSkill(uint256 _skillId) public onlyAdmin {
        skillById[_skillId].disabled = false;

        emit SkillUpdated(_skillId);
    }

    function enableSkillGroup(uint256 _skillGroupId) public onlyAdmin {
        skillGroupById[_skillGroupId].disabled = false;

        emit SkillGroupUpdated(_skillGroupId);
    }

    function getSkillById(uint256 _skillId)
        external
        view
        returns (Skill memory)
    {
        return skillById[_skillId];
    }

    function getSkillsByGroupId(uint256 _skillGroupId)
        external
        view
        returns (Skill[] memory skills)
    {
        return skillsByGroupId[_skillGroupId];
    }
}
