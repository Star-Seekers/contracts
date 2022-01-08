// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IClone.sol";
import "./interfaces/IStats.sol";
import "./interfaces/ICRED.sol";
import "./interfaces/IChainlinkAggregator.sol";

/// @notice this contract serves as the central location for clone s
contract CloningFacility is UniversalData {
    struct CloneData {
        address owner;
        bool for_sale;
        string uri; // IPFS url
        uint256 price;
        uint256 id;
    }

    /// @notice cloneData[cloneId] => CloneData struct
    mapping(uint256 => CloneData) cloneData;
    /// @notice clonesOwnedByAddress[playerWalletAddress] => array[cloneId]
    mapping(address => uint256[]) clonesOwnedByAddress;
    /// @notice stats[cloneId][Stat.stat] => statLevel
    mapping(uint256 => mapping(IStats.Stat => uint256)) stats;

    event CloneCreated(uint256 cloneId, address owner);

    constructor(address _gameManager) UniversalData(_gameManager) {}

    /// @notice Creates a new clone
    /// @dev gets the price of the chains base token from chainlink
    /// @param _uri json IPFS endpoint
    function create(string memory _uri) public payable notInMaintenance {
        require(
            gameManager.chainlinkFeed() != address(0),
            "Star Seekers: No chainlink feed set"
        );
        ICred cred = ICred(gameManager.contractAddresses("CRED"));

        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            gameManager.chainlinkFeed()
        );
        (, int256 purchaseTokenUsdPrice, , , ) = priceFeed.latestRoundData();

        uint256 cloneCostInBaseToken = gameManager.cloneCost() /
            uint256(purchaseTokenUsdPrice);
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

    /// @notice changes the uri for a given clone id
    /// @dev should only be callable by other game contracts
    /// @param _cloneId uint256 cloneId
    /// @return CloneData struct
    function getCloneData(uint256 _cloneId)
        public
        view
        returns (CloneData memory)
    {
        return cloneData[_cloneId];
    }

    /// @notice gets the level for a specific stat on a specific clone
    /// @dev should only be callable by other game contracts
    /// @param _cloneId clone id
    /// @param _stat clone stat to retrieve level of
    /// @return uint256 clone stat level
    function getCloneStatLevel(uint256 _cloneId, IStats.Stat _stat)
        public
        view
        returns (uint256)
    {
        return stats[_cloneId][_stat];
    }

    /// @notice gets clone URI
    /// @dev should be IPFS JSON endpoint
    /// @param _cloneId clone id
    /// @return string clone uri
    function getCloneUri(uint256 _cloneId) public view returns (string memory) {
        string memory uri = cloneData[_cloneId].uri;
        return uri;
    }

    /// @notice changes the owner of a given clone to the given address
    /// @dev should only be callable by other game contracts
    /// @param _newOwner address of the new owner
    /// @param _cloneId cloneId of the
    /// @return bool success
    function changeOwner(address _newOwner, uint256 _cloneId)
        external
        onlyGameContract
        returns (bool)
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

        return true;
    }

    /// @notice changes the owner of a given clone to the given address
    /// @dev should only be callable by other game contracts
    /// @param _cloneId uint256 clone id
    /// @param _forSale bool sale state
    /// @param _price uint256 price of clone
    /// @return bool success
    function changeSalesState(
        uint256 _cloneId,
        bool _forSale,
        uint256 _price
    ) external onlyGameContract returns (bool) {
        cloneData[_cloneId].for_sale = _forSale;

        cloneData[_cloneId].price = _price;

        return true;
    }

    /// @notice changes the uri for a given clone id
    /// @dev should only be callable by other game contracts
    /// @param _cloneId uint256 cloneId
    /// @param _uri string ipfs url for json endpoint
    function changeUri(uint256 _cloneId, string memory _uri)
        external
        onlyGameContract
        returns (bool)
    {
        cloneData[_cloneId].uri = _uri;

        return true;
    }

    /// @notice increases a clones stat by the given amount
    /// @dev should only be callable by other game contracts
    /// @param _cloneId clone id
    /// @param _stat stat enum
    /// @param _amount uin256 amount to increase stat by
    /// @return bool success
    function increaseStat(
        uint256 _cloneId,
        IStats.Stat _stat,
        uint256 _amount
    ) external onlyGameContract returns (bool) {
        stats[_cloneId][_stat] += _amount;

        return true;
    }

    /// @notice decreases a clones stat by the given amount
    /// @dev should only be callable by other game contracts
    /// @param _cloneId clone id
    /// @param _stat stat enum
    /// @param _amount uin256 amount to decrease stat by
    /// @return bool success
    function decreaseStat(
        uint256 _cloneId,
        IStats.Stat _stat,
        uint256 _amount
    ) external onlyGameContract returns (bool) {
        stats[_cloneId][_stat] -= _amount;

        return true;
    }

    receive() external payable {
        (bool sent, ) = gameManager.federation().call{value: msg.value}("");
        require(sent, "Star Seekers: Failed to send payment token");
    }
}
