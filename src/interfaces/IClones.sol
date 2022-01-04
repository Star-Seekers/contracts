// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./IStats.sol";

interface IClones {
    struct CloneData {
        address owner;
        bool for_sale;
        string uri; // IPFS url
        uint256 price;
        uint256 id;
    }

    function changeOwner(address newOwner, uint256 cloneId) external;

    function changeSalesStatus(
        uint256 cloneId,
        bool status,
        uint256 price
    ) external;

    function changeUri(uint256 cloneId, string memory uri) external;

    function getCloneData(uint256 cloneId)
        external
        view
        returns (CloneData memory);

    function getCloneStatLevel(uint256 cloneId, IStats.Stat stat)
        external
        view
        returns (uint256);

    function getCloneUri(uint256 cloneId) external view returns (string memory);

    function increaseStat(
        uint256 cloneId,
        IStats.Stat stat,
        uint256 amount
    ) external;

    function decreaseStat(
        uint256 cloneId,
        IStats.Stat stat,
        uint256 amount
    ) external;
}
