// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/ISkills.sol";
import "./interfaces/IStats.sol";
import "./interfaces/ICloningFacility.sol";

/// @notice this contract serves as the central location for clone s
contract Learning is UniversalData {
    bool internal initialized = false;

    struct LearningState {
        bool is_learning;
        uint256 end_time;
        uint256 learning;
        uint256 start_time;
        uint256 total_learning_points;
    }
    /// @notice learningState[_cloneId] => LearningState
    mapping(uint256 => LearningState) learningState;

    struct LearningLog {
        uint256 learning_points;
        uint256 skill_level;
    }
    /// @notice learningLog[_cloneId][_skillId] => LearningLog
    mapping(uint256 => mapping(uint256 => LearningLog)) learningLog;

    /// @notice emitted any time we update the learning state
    event LearningStateUpdated(uint256 cloneId, LearningState learningState);

    constructor() {}

    function initialize(address _gameManager) public {
        require(!initialized, "Star Seekers: Already initialized");

        gameManager = GameManager(_gameManager);
        initialized = true;
    }

    /// @notice after training has completed call this function to update state
    /// @dev can only be called when game is not in maintenance, the clone is not for sale,
    /// and only the clone owner.
    /// @param _cloneId the clone id to complete learning on
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
            "Star Seekers: Not finished learning skill"
        );

        _resetAndUpdateLearningState(_cloneId);

        emit LearningStateUpdated(_cloneId, learningState[_cloneId]);
    }

    /// @notice start training on a specific clone
    /// @dev can only be called when game is not in maintenance, the clone is not for sale,
    /// and only the clone owner.
    /// @param _cloneId clone id to start training on
    /// @param _skillId skill id to start training on
    function startLearning(uint256 _cloneId, uint256 _skillId)
        public
        notInMaintenance
        notForSale(_cloneId)
        onlyCloneOwner(msg.sender, _cloneId)
    {
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

        emit LearningStateUpdated(_cloneId, learningState[_cloneId]);
    }

    /// @notice stop training on a skill that's still in training
    /// @dev can only be called when game is not in maintenance, the clone is not for sale,
    /// and only the clone owner.
    /// @param _cloneId the clone id to complete learning on
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

        emit LearningStateUpdated(_cloneId, learningState[_cloneId]);
    }

    /// @notice retrieve a clones learning log for a specific skill
    /// @param _cloneId the clone id to retrieve
    /// @param _skillId the skill id of the skill to retrieve the learning log of.
    /// @return LearningLog
    function getLearningLog(uint256 _cloneId, uint256 _skillId)
        public
        view
        returns (LearningLog memory)
    {
        return learningLog[_cloneId][_skillId];
    }

    /// @notice get the learning state of a specific clone
    /// @param _cloneId the clone id to retrieve
    /// @return LearningState
    function getLearningState(uint256 _cloneId)
        public
        view
        returns (LearningState memory)
    {
        return learningState[_cloneId];
    }

    /// @notice calculate learning points earned
    /// @param _skill Skill enum skill they are training
    /// @param _cloneId the id of a clone
    /// @return uint256 returns time remaining in minutes as a timestamp
    function _calculateLearningPointsEarned(
        ISkills.Skill memory _skill,
        uint256 _cloneId
    ) internal view returns (uint256) {
        uint256 startTime = learningState[_cloneId].start_time;
        uint256 currentTime = block.timestamp;
        uint256 endTime = learningState[_cloneId].end_time;
        uint256 trainingTime;

        if (currentTime > endTime) {
            trainingTime = (endTime - startTime) / 1 minutes;
        } else {
            trainingTime = (currentTime - startTime) / 1 minutes;
        }

        ICloningFacility cloningFacility = ICloningFacility(
            gameManager.contractAddresses("CloningFacility")
        );

        uint256 learningPointsPerMinute = _calculateLearningPointsPerMinute(
            cloningFacility.getCloneStatLevel(
                _cloneId,
                _skill.primary_attribute
            ),
            cloningFacility.getCloneStatLevel(
                _cloneId,
                _skill.secondary_attribute
            )
        );

        return (trainingTime * learningPointsPerMinute);
    }

    /// @notice calculate the amount of learning time remaining based on the clones stats
    /// @param _skill Skill enum
    /// @param _cloneId cloneId the cloneId
    /// @return uint256 amount of time in minutes remaining
    function _calculateLearningTimeRemaining(
        ISkills.Skill memory _skill,
        uint256 _cloneId
    ) internal view returns (uint256) {
        ICloningFacility cloningFacility = ICloningFacility(
            gameManager.contractAddresses("CloningFacility")
        );

        uint256 primaryAttributeLevel = cloningFacility.getCloneStatLevel(
            _cloneId,
            _skill.primary_attribute
        );

        uint256 secondaryAttributeLevel = cloningFacility.getCloneStatLevel(
            _cloneId,
            _skill.secondary_attribute
        );

        /// @dev calculate how many learning points are required to reach next level
        uint256 learningPointsRequired = _calculateLearningPointsRequired(
            _skill,
            _cloneId
        );

        uint256 learningPointsPerMinute = _calculateLearningPointsPerMinute(
            primaryAttributeLevel,
            secondaryAttributeLevel
        );

        return
            ((learningPointsRequired / learningPointsPerMinute) +
                (
                    learningPointsRequired % learningPointsPerMinute == 0
                        ? 0
                        : 1
                )) * 1 minutes;
    }

    /// @notice calculates required learning points based on player stats
    /// @param _skill skill struct
    /// @param _cloneId cloneId
    /// @return uint256 learning points required to level a skill up
    function _calculateLearningPointsRequired(
        ISkills.Skill memory _skill,
        uint256 _cloneId
    ) internal view returns (uint256) {
        ICloningFacility cloningFacility = ICloningFacility(
            gameManager.contractAddresses("CloningFacility")
        );

        uint256 primaryAttributeLevel = cloningFacility.getCloneStatLevel(
            _cloneId,
            _skill.primary_attribute
        );

        uint256 secondaryAttributeLevel = cloningFacility.getCloneStatLevel(
            _cloneId,
            _skill.secondary_attribute
        );
        uint256 baseLearningPoints = _calculateBaseLearningPoints(
            _skill.multiplier,
            learningLog[_cloneId][_skill.id].skill_level + 1
        );
        uint256 currentLearningPoints = learningLog[_cloneId][_skill.id]
            .learning_points;

        return
            (((baseLearningPoints) /
                (primaryAttributeLevel + (secondaryAttributeLevel / 2))) *
                10**3) - currentLearningPoints;
    }

    /// @notice calculates base learning points based on skill multiplier and the skill
    /// level being trained
    /// @param _multiplier skill multiplier, can be found on Skill struct
    /// @param _skillLevel players skill level
    /// @return uint256 base learning points

    function _calculateBaseLearningPoints(
        uint256 _multiplier,
        uint256 _skillLevel // player skill level
    ) internal pure returns (uint256) {
        return ((250 * _multiplier) * 6**(_skillLevel - 1));
    }

    /// @notice calculates how many learning points a player earns based on their stats per minute
    /// @param _primaryPlayerStatAttribute players stat level
    /// @param _secondaryPlayerStatAttribute secondary stat level
    /// @return uint256 learning points per minute based on the stat levels of the player
    function _calculateLearningPointsPerMinute(
        uint256 _primaryPlayerStatAttribute, // player stat attribute
        uint256 _secondaryPlayerStatAttribute // player stat attribute
    ) internal pure returns (uint256) {
        return
            ((((_primaryPlayerStatAttribute * 1) * (10**3)) / 4)) +
            ((((_secondaryPlayerStatAttribute * 1) * (10**3)) / 8));
    }

    /// @notice checks if a skill meets the requirements to be learned
    /// @param _skill Skill struct
    /// @param _cloneId clone id
    /// @return bool success
    function _isLearnable(ISkills.Skill memory _skill, uint256 _cloneId)
        internal
        view
        returns (bool)
    {
        /// @dev checks that players has not reached max skill level
        require(
            learningLog[_cloneId][_skill.id].skill_level < 5,
            "Star Seekers: Skill already at max"
        );
        /// @dev checks for skill dependencies
        if (_skill.dependency) {
            /// @dev checks that the dependent skill is at level 5
            require(
                learningLog[_cloneId][_skill.dependency_id].skill_level == 5,
                "Skill Seekers: Dependent skill must be level 5 before training"
            );
        }

        require(
            !learningState[_cloneId].is_learning,
            "Star Seekers: Already learning, please stop current skill."
        );

        require(_skill.id != 0, "Star Seekers: Invalid skill");

        return true;
    }

    /// @notice resets the learning state and updates the learning log
    /// @param _cloneId cloneId
    /// @return bool success
    function _resetAndUpdateLearningState(uint256 _cloneId)
        internal
        returns (bool)
    {
        /// @dev creats an instance of the Skills contract using the address stored on GameManager
        uint256 learning = learningState[_cloneId].learning;

        ISkills skillsInstance = ISkills(
            gameManager.contractAddresses("Skills")
        );
        /// @dev loads skill definitions
        ISkills.Skill memory skill = skillsInstance.getSkillById(learning);
        uint256 learningPointsEarned = _calculateLearningPointsEarned(
            skill,
            _cloneId
        );

        if (block.timestamp >= learningState[_cloneId].end_time) {
            learningLog[_cloneId][learning].skill_level += 1;
            learningLog[_cloneId][learning].learning_points = 0;
        } else {
            learningLog[_cloneId][learning]
                .learning_points = learningPointsEarned;
        }

        learningState[_cloneId].total_learning_points += learningPointsEarned;

        /// @dev reset learning state
        learningState[_cloneId].start_time = 0;
        learningState[_cloneId].end_time = 0;
        learningState[_cloneId].is_learning = false;
        learningState[_cloneId].learning = 0;

        return true;
    }
}
