// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;
import "./IStats.sol";

interface ISkills {
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

    function getSkillById(uint256 skillId) external returns (Skill memory);

    function getSkillsByGroupId(uint256 skillGroupId)
        external
        returns (uint256[] memory);

    function getSkillByName(string memory name) external returns (Skill memory);
}
