// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IStats.sol";

contract Skills is UniversalData {
    bool internal initialized;

    struct Skill {
        bool dependency;
        IStats.Stat primary_attribute;
        IStats.Stat secondary_attribute;
        string icon; // ipfs url
        string name;
        uint256 dependency_id;
        uint256 id;
        uint256 multiplier;
    }

    /// @notice skillById[skillId] => Skill struct;
    mapping(uint256 => Skill) skillById;
    /// @notice skillByName["SkillName"] => Skill struct;
    mapping(string => Skill) skillByName;

    /// @notice emitted when a new skill is added to the database by the admin;
    event SkillAdded(uint256 skillId);
    /// @notice emitted when a new skill is removed from the database by the admin;
    event SkillRemoved(uint256 skillId);

    constructor() {}

    function initialize(address _gameManager) public {
        require(!initialized, "Star Seekers: Already initialized");

        gameManager = GameManager(_gameManager);
        initialized = true;
    }

    /// @notice adds a new skill to the database of trainable skills and adds it to a skill group
    /// @param _skill Skill struct
    function addSkill(Skill memory _skill) public onlyAdmin {
        skillById[_skill.id] = _skill;
        skillByName[_skill.name] = _skill;

        emit SkillAdded(_skill.id);
    }

    /// @notice removes a skill from the database and removes it from the skillgroup
    /// @param _skillId skill id
    function removeSkill(uint256 _skillId) public onlyAdmin {
        delete skillByName[skillById[_skillId].name];
        delete skillById[_skillId];

        emit SkillRemoved(_skillId);
    }

    /// @notice get a Skill struct by id
    /// @param _skillId skill id
    /// @return Skill struct
    function getSkillById(uint256 _skillId) public view returns (Skill memory) {
        return skillById[_skillId];
    }

    /// @notice gets a Skill by name
    /// @param _name string name of skill lookup
    /// @return Skill struct
    function getSkillByName(string memory _name)
        public
        view
        returns (Skill memory)
    {
        return skillByName[_name];
    }
}
