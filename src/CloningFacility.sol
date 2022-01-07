// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IClone.sol";
import "./interfaces/IStats.sol";
import "./interfaces/ICRED.sol";
import "./interfaces/IChainlinkAggregator.sol";

/// @notice this contract serves as the central location for clone s
contract CloningFacility is UniversalData {
    /// @dev cloneData[_cloneId] => Data
    struct CloneData {
        address owner;
        bool for_sale;
        string uri; // IPFS url
        uint256 price;
        uint256 id;
    }
    mapping(uint256 => CloneData) cloneData;
    mapping(address => uint256[]) clonesOwnedByAddress;
    /// @dev Clone stats
    mapping(uint256 => mapping(IStats.Stat => uint256)) stats;

    event CloneCreated(uint256 cloneId, address owner);

    constructor(address _gameManager) UniversalData(_gameManager) {}

    /// @notice Creates a new clone
    /// @dev gets the price of the chains base token from chainlink
    /// sends the cost of token which is adjustable on game manager to the contract, and
    /// the contract sends it to the federation address.
    function create(string memory _uri) public payable notInMaintenance {
        ICred cred = ICred(gameManager.contractAddresses("CRED"));

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            gameManager.chainlinkFeed()
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        uint256 cloneCostInBaseToken = gameManager.cloneCost() / uint256(price);
        require(
            msg.value >= cloneCostInBaseToken,
            "Star Seekers: Invalid payment amount"
        );

        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Star Seekers: Failed to send payment token");

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
        clonesOwnedByAddress[msg.sender].push(data.id);

        if (
            gameManager.startingCred() > 0 &&
            gameManager.hasReceivedStartingCred(msg.sender) == false
        ) {
            cred.mint(msg.sender, gameManager.startingCred());
            gameManager.updateHasReceivedStartingCred(msg.sender);
        }

        emit CloneCreated(newCloneId, msg.sender);
    }

    function changeOwner(address _newOwner, uint256 _cloneId)
        external
        onlyGameContract
    {
        uint256[] memory clones = clonesOwnedByAddress[
            cloneData[_cloneId].owner
        ];

        for (uint256 i = 0; i <= clones.length; i += 1) {
            if (clones[i] == _cloneId) {
                delete clones[i];
                clonesOwnedByAddress[cloneData[_cloneId].owner] = clones;
            }
        }
        cloneData[_cloneId].owner = _newOwner;
        clonesOwnedByAddress[_newOwner].push(_cloneId);
    }

    function changeSalesStatus(
        uint256 _cloneId,
        bool _status,
        uint256 _price
    ) external onlyGameContract {
        cloneData[_cloneId].for_sale = _status;
        cloneData[_cloneId].price = _price;
    }

    function changeUri(uint256 _cloneId, string memory _uri)
        external
        onlyGameContract
    {
        cloneData[_cloneId].uri = _uri;
    }

    function getCloneData(uint256 _cloneId)
        external
        view
        onlyGameContract
        returns (CloneData memory)
    {
        return cloneData[_cloneId];
    }

    function getCloneStatLevel(uint256 _cloneId, IStats.Stat _stat)
        external
        view
        onlyGameContract
        returns (uint256)
    {
        return stats[_cloneId][_stat];
    }

    function getCloneUri(uint256 _cloneId)
        external
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
    ) external onlyGameContract {
        stats[_cloneId][_stat] += _amount;
    }

    function decreaseStat(
        uint256 _cloneId,
        IStats.Stat _stat,
        uint256 _amount
    ) external onlyGameContract {
        stats[_cloneId][_stat] -= _amount;
    }

    receive() external payable {
        gameManager.federation().transfer(msg.value);
    }
}