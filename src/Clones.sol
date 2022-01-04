// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";

import "./Skills.sol";
import "./Implants.sol";
import "./interfaces/IClone.sol";

/// @notice this contract serves as the central location for clone s
contract Clones is UniversalData {
    /// @dev cloneData[_cloneId] => Data
    struct CloneData {
        address owner;
        string uri; // IPFS url
        uint256 id;
    }
    mapping(uint256 => CloneData) public cloneData;
    mapping(address => CloneData[]) public clonesOwnedBy;

    constructor(address _gameManager) UniversalData(_gameManager) {}

    function create(address _owner, string memory _uri)
        internal
        onlyGameContract
    {
        uint256 newCloneId = IClone(gameManager.contractAddresses("Clone"))
            .create(_owner, _uri);

        CloneData memory data = CloneData({
            owner: _owner,
            uri: _uri, // IPFS json endpoint
            id: newCloneId
        });

        cloneData[newCloneId] = data;
        clonesOwnedBy[_owner].push(data);
    }

    function changeOwner(address _newOwner, uint256 _cloneId)
        internal
        onlyGameContract
    {
        cloneData[_cloneId].owner = _newOwner;
    }

    function changeUri(uint256 _cloneId, string memory _uri)
        internal
        onlyGameContract
    {
        cloneData[_cloneId].uri = _uri;
    }
}
