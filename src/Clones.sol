// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IClone.sol";
import "./interfaces/IStats.sol";

/// @notice this contract serves as the central location for clone s
contract Clones is UniversalData {
    /// @dev cloneData[_cloneId] => Data
    struct CloneData {
        address owner;
        bool for_sale;
        string uri; // IPFS url
        uint256 price;
        uint256 id;
    }
    mapping(uint256 => CloneData) public cloneData;
    mapping(address => CloneData[]) public clonesOwnedByAddress;

    /// @dev Clone stats
    /// stats[_cloneId][Stat] => Stat level
    mapping(uint256 => mapping(IStats.Stat => uint256)) public stats;

    event CloneCreated(uint256 cloneId, address owner);

    constructor(address _gameManager) UniversalData(_gameManager) {}

    function create(string memory _uri) public notInMaintenance {
        uint256 newCloneId = IClone(gameManager.contractAddresses("Clone"))
            .create(msg.sender);

        CloneData memory data = CloneData({
            owner: msg.sender,
            for_sale: false,
            uri: _uri, // IPFS json endpoint
            price: 0,
            id: newCloneId
        });

        cloneData[newCloneId] = data;
        clonesOwnedByAddress[msg.sender].push(data);

        emit CloneCreated(newCloneId, msg.sender);
    }

    function changeOwner(address _newOwner, uint256 _cloneId)
        internal
        onlyGameContract
    {
        CloneData[] memory clones = clonesOwnedByAddress[
            cloneData[_cloneId].owner
        ];

        for (uint256 i = 0; i <= clones.length; i += 1) {
            if (clones[i].id == _cloneId) {
                delete clones[i];
                clonesOwnedByAddress[cloneData[_cloneId].owner] = clones;
            }
        }
        cloneData[_cloneId].owner = _newOwner;
        clonesOwnedByAddress[_newOwner].push(cloneData[_cloneId]);
    }

    function changeSalesStatus(
        uint256 _cloneId,
        bool _status,
        uint256 _price
    ) internal onlyGameContract {
        cloneData[_cloneId].for_sale = _status;
        cloneData[_cloneId].price = _price;
    }

    function changeUri(uint256 _cloneId, string memory _uri)
        internal
        onlyGameContract
    {
        cloneData[_cloneId].uri = _uri;
    }

    function getCloneData(uint256 _cloneId)
        internal
        view
        onlyGameContract
        returns (CloneData memory)
    {
        return cloneData[_cloneId];
    }

    function getCloneStatLevel(uint256 _cloneId, IStats.Stat _stat)
        internal
        view
        onlyGameContract
        returns (uint256)
    {
        return stats[_cloneId][_stat];
    }

    function getCloneUri(uint256 _cloneId)
        internal
        view
        onlyGameContract
        returns (string memory)
    {
        string memory uri = cloneData[_cloneId].uri;
        return uri;
    }

    function increaseStat(
        uint256 _cloneId,
        IStats.Stat _stat,
        uint256 _amount
    ) internal onlyGameContract {
        stats[_cloneId][_stat] += _amount;
    }

    function decreaseStat(
        uint256 _cloneId,
        IStats.Stat _stat,
        uint256 _amount
    ) internal onlyGameContract {
        stats[_cloneId][_stat] -= _amount;
    }
}
