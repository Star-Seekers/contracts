// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IClone.sol";

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

    constructor(address _gameManager) UniversalData(_gameManager) {}

    function create(string memory _uri) public notInMaintenance {
        uint256 newCloneId = IClone(gameManager.contractAddresses("Clone"))
            .create(msg.sender);

        CloneData memory data = CloneData({
            owner: msg.sender,
            uri: _uri, // IPFS json endpoint
            id: newCloneId,
            price: 0,
            for_sale: false
        });

        cloneData[newCloneId] = data;
        clonesOwnedByAddress[msg.sender].push(data);
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

    function getCloneUri(uint256 _cloneId)
        internal
        view
        onlyGameContract
        returns (string memory)
    {
        string memory uri = cloneData[_cloneId].uri;
        return uri;
    }
}
