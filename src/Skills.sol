// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IStats.sol";

contract Skills is UniversalData {
    uint256 private skillIndex;
    uint256 private skillGroupIndex;

    struct Skill {
        bool dependency;
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

    /// @notice skillById[skillId] => Skill struct;
    mapping(uint256 => Skill) internal skillById;

    struct SkillGroup {
        uint256 id;
        string name;
    }
    /// @notice skillGroupById[skillGroupId] => SkillGroup struct;
    mapping(uint256 => SkillGroup) internal skillGroupById;
    /// @notice skillsByGroupId[skillGroupId] => skillId[] array of skill ids;
    mapping(uint256 => uint256[]) internal skillsByGroupId;

    /// @notice emitted when a new skill is added to the database by the admin;
    event SkillAdded(uint256 skillId);
    /// @notice emitted when a new skill is removed from the database by the admin;
    event SkillRemoved(uint256 skillId);
    /// @notice emitted when a new skill group is added to the database by the admin;
    event SkillGroupAdded(uint256 skillGroupId);

    constructor(address _gameManager) UniversalData(_gameManager) {}

    /// @notice adds a new skill to the database of trainable skills and adds it to a skill group
    /// @param _skill Skill struct
    function addSkill(Skill memory _skill) public onlyAdmin {
        _skill.id = skillIndex;
        skillById[skillIndex] = _skill;
        skillsByGroupId[_skill.group_id].push(_skill.id);
        skillIndex += 1;

        emit SkillAdded(_skill.id);
    }

    /// @notice adds a new skill group to the database
    /// @param _skillGroup SkillGroup struct
    function addSkillGroup(SkillGroup memory _skillGroup) public onlyAdmin {
        _skillGroup.id = skillGroupIndex;
        skillGroupById[skillGroupIndex] = _skillGroup;
        skillGroupIndex += 1;

        emit SkillGroupAdded(_skillGroup.id);
    }

    /// @notice removes a skill from the database and removes it from the skillgroup
    /// @param _skillId skill id
    function removeSkill(uint256 _skillId) public onlyAdmin {
        uint256[] memory skills = skillsByGroupId[skillById[_skillId].group_id];

        for (uint256 i = 0; i <= skills.length; i += 1) {
            if (skills[i] == _skillId) {
                delete skills[i];

                skillsByGroupId[skillById[_skillId].group_id] = skills;
            }
        }
        delete skillById[_skillId];

        emit SkillRemoved(_skillId);
    }

    /// @notice get a Skill struct by id
    /// @param _skillId skill id
    /// @return Skill struct
    function getSkillById(uint256 _skillId)
        external
        view
        returns (Skill memory)
    {
        return skillById[_skillId];
    }

    /// @notice get skills by group id
    /// @param _skillGroupId skill group id
    /// @return Skill[] array of Skill structs
    function getSkillsByGroupId(uint256 _skillGroupId)
        external
        view
        returns (uint256[] memory)
    {
        return skillsByGroupId[_skillGroupId];
    }
}
