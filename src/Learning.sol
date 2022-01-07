// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/ISkills.sol";
import "./interfaces/IStats.sol";
import "./interfaces/IClones.sol";

/// @notice this contract serves as the central location for clone s
contract Learning is UniversalData {
    struct LearningState {
        bool is_learning;
        uint256 end_time;
        uint256 learning;
        uint256 start_time;
    }
    /// @dev learningState[_cloneId] => LearningState
    mapping(uint256 => LearningState) learningState;

    /// @dev learningLog[_cloneId][_skillId] => LearningLog
    struct LearningLog {
        uint256 learningPoints;
        uint256 skillLevel;
    }
    mapping(uint256 => mapping(uint256 => LearningLog)) learningLog;

    event LearningStateUpdated(uint256 cloneId);

    constructor(address _gameManager) UniversalData(_gameManager) {}

    /// @notice after training has completed call this function to update state
    function completeLearning(uint256 _cloneId)
        public
        notInMaintenance
        notForSale(_cloneId)
        onlyCloneOwner(msg.sender, _cloneId)
    {
        require(
            learningState[_cloneId].is_learning,
            "Star Seekers: Not currently training any skills"
        );
        require(
            learningState[_cloneId].end_time <= block.timestamp,
            "Star Seekers: Skill has not finished training"
        );

        _resetAndUpdateLearningState(_cloneId);

        emit LearningStateUpdated(_cloneId);
    }

    /// @notice public functions
    function startLearning(uint256 _cloneId, uint256 _skillId)
        public
        notInMaintenance
        notForSale(_cloneId)
        onlyCloneOwner(msg.sender, _cloneId)
    {
        require(
            !learningState[_cloneId].is_learning,
            "Star Seekers: Already learning skill."
        );
        /// @dev creats an instance of the Skills contract using the address stored on GameManager
        ISkills skillsInstance = ISkills(
            gameManager.contractAddresses("Skills")
        );
        /// @dev loads skill definitions
        ISkills.Skill memory skill = skillsInstance.getSkillById(_skillId);
        /// @dev check if clone is able to learn this skill
        _isLearnable(skill, _cloneId);

        learningState[_cloneId].start_time = block.timestamp;
        learningState[_cloneId].end_time =
            block.timestamp +
            _calculateLearningTimeRemaining(skill, _cloneId);
        learningState[_cloneId].is_learning = true;
        learningState[_cloneId].learning = _skillId;

        emit LearningStateUpdated(_cloneId);
    }

    /// @notice public functions
    function stopLearning(uint256 _cloneId)
        public
        notInMaintenance
        notForSale(_cloneId)
        onlyCloneOwner(msg.sender, _cloneId)
    {
        require(
            learningState[_cloneId].is_learning,
            "Star Seekers: Not currently training any skills"
        );
        require(
            learningState[_cloneId].end_time > block.timestamp,
            "Star Seekers: Skill has already finished training"
        );

        _resetAndUpdateLearningState(_cloneId);

        emit LearningStateUpdated(_cloneId);
    }

    function getLearningLog(uint256 _cloneId, uint256 _skillId)
        external
        view
        returns (LearningLog memory)
    {
        return learningLog[_cloneId][_skillId];
    }

    function getLearningState(uint256 _cloneId)
        external
        view
        returns (LearningState memory)
    {
        return learningState[_cloneId];
    }

    /// @notice private functions
    /// @notice returns time remaining in minutes as a timestamp
    function _calculateLearningPointsEarned(
        ISkills.Skill memory _skill,
        uint256 _cloneId
    ) internal view returns (uint256) {
        uint256 startTime = learningState[_cloneId].start_time;
        uint256 currentTime = block.timestamp;
        uint256 endTime = learningState[_cloneId].end_time;
        uint256 trainingTime;

        if (currentTime > endTime) {
            trainingTime = (endTime - startTime) % 60;
        } else {
            trainingTime = (currentTime - startTime) % 60;
        }

        IClones clonesInstance = IClones(
            gameManager.contractAddresses("Clones")
        );

        uint256 learningPointsPerMinute = _calculateLearningPointsPerMinute(
            clonesInstance.getCloneStatLevel(
                _cloneId,
                _skill.primary_attribute
            ),
            clonesInstance.getCloneStatLevel(
                _cloneId,
                _skill.secondary_attribute
            )
        );

        return trainingTime * learningPointsPerMinute;
    }

    function _calculateLearningTimeRemaining(
        ISkills.Skill memory _skill,
        uint256 _cloneId
    ) internal view returns (uint256) {
        IClones clonesInstance = IClones(
            gameManager.contractAddresses("Clones")
        );

        uint256 primaryAttributeLevel = clonesInstance.getCloneStatLevel(
            _cloneId,
            _skill.primary_attribute
        );

        uint256 secondaryAttributeLevel = clonesInstance.getCloneStatLevel(
            _cloneId,
            _skill.secondary_attribute
        );

        /// @dev calculate how many learning points are required to reach next level
        uint256 learningPointsRequired = _calculateLearningPointsRequired(
            _skill,
            _cloneId,
            primaryAttributeLevel,
            secondaryAttributeLevel
        );

        uint256 learningPointsPerMinute = _calculateLearningPointsPerMinute(
            primaryAttributeLevel,
            secondaryAttributeLevel
        );

        return (learningPointsRequired / learningPointsPerMinute) * 1 minutes;
    }

    /// @notice calculates required learning points based on player stats
    function _calculateLearningPointsRequired(
        ISkills.Skill memory _skill,
        uint256 _cloneId,
        uint256 _primaryPlayerStatAttribute, // player attribute level
        uint256 _secondaryPlayerStatAttribute // player attribute level
    ) internal view returns (uint256) {
        return
            (_calculateBaseLearningPoints(
                _skill.multiplier,
                learningLog[_cloneId][_skill.id].skillLevel + 1
            ) - learningLog[_cloneId][_skill.id].learningPoints) /
            (_primaryPlayerStatAttribute + (_secondaryPlayerStatAttribute / 2));
    }

    /// @notice calculates base learning points based on skill multiplier and the skill level being trained
    function _calculateBaseLearningPoints(
        uint256 _multiplier,
        uint256 _skillLevel // player skill level
    ) internal pure returns (uint256) {
        return (250 * _multiplier) * 6**(_skillLevel - 1);
    }

    /// @notice calculates how many learning points a player earns based on their stats
    function _calculateLearningPointsPerMinute(
        uint256 _primaryPlayerStatAttribute, // player stat attribute
        uint256 _secondaryPlayerStatAttribute // player stat attribute
    ) private pure returns (uint256) {
        return
            (_primaryPlayerStatAttribute * 1) /
            2 +
            (_secondaryPlayerStatAttribute * 1) /
            4;
    }

    /// @notice checks if a skill meets the requirements to be learned
    function _isLearnable(ISkills.Skill memory _skill, uint256 _cloneId)
        internal
        view
        returns (bool)
    {
        /// @dev checks that players has not reached max skill level
        require(
            learningLog[_cloneId][_skill.id].skillLevel < 5,
            "Star Seekers: Skill already at max"
        );
        /// @dev checks for skill dependencies
        if (_skill.dependency) {
            /// @dev checks that the dependent skill is at level 5
            require(
                learningLog[_cloneId][_skill.dependency_id].skillLevel == 5,
                "Skill Seekers: Dependent skill must be level 5 before training"
            );
        }

        return true;
    }

    function _resetAndUpdateLearningState(uint256 _cloneId) internal {
        /// @dev creats an instance of the Skills contract using the address stored on GameManager
        ISkills skillsInstance = ISkills(
            gameManager.contractAddresses("Skills")
        );
        /// @dev loads skill definitions
        ISkills.Skill memory skill = skillsInstance.getSkillById(
            learningState[_cloneId].learning
        );

        learningLog[_cloneId][learningState[_cloneId].learning]
            .learningPoints = _calculateLearningPointsEarned(skill, _cloneId);

        /// @dev reset learning state
        learningState[_cloneId].start_time = 0;
        learningState[_cloneId].end_time = 0;
        learningState[_cloneId].is_learning = false;
        learningState[_cloneId].learning = 0;
    }
}
