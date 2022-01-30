// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./IStats.sol";

interface ICloningFacility {
    struct CloneData {
        address owner;
        bool for_sale;
        string uri; // IPFS url
        uint256 price;
        uint256 id;
    }

    function create(string memory uri) external payable;

    function changeOwner(address newOwner, uint256 cloneId)
        external
        returns (bool);

    function changeSalesStatus(
        uint256 cloneId,
        bool status,
        uint256 price
    ) external returns (bool);

    function changeUri(uint256 cloneId, string memory uri)
        external
        returns (bool);

    function getCloneData(uint256 cloneId)
        external
        view
        returns (CloneData memory);

    function getClonesOwnedByAddress(address owner)
        external
        view
        returns (uint256[] memory);

    function getCloneStatLevel(uint256 cloneId, IStats.Stat stat)
        external
        view
        returns (uint256);

    function getCloneUri(uint256 cloneId) external view returns (string memory);

    function increaseStat(
        uint256 cloneId,
        IStats.Stat stat,
        uint256 amount
    ) external returns (bool);

    function decreaseStat(
        uint256 cloneId,
        IStats.Stat stat,
        uint256 amount
    ) external returns (bool);
}
