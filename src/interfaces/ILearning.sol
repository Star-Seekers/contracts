// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;
import "./IStats.sol";

interface ILearning {
    struct LearningState {
        bool is_learning;
        uint256 end_time;
        uint256 learning;
        uint256 start_time;
    }
    struct LearningLog {
        uint256 learningPoints;
        uint256 skillLevel;
    }

    function getLearningLog(uint256 cloneId, uint256 skillId)
        external
        returns (LearningLog memory);

    function getLearningState(uint256 cloneId)
        external
        returns (LearningState memory);
}
