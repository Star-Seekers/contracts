// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IClone.sol";
import "./interfaces/IStats.sol";
import "./interfaces/ICRED.sol";
import "./interfaces/IChainlinkAggregator.sol";

import "hardhat/console.sol";

/// @notice this contract serves as the central location for clone s
contract CloningFacility is UniversalData {
    bool internal initialized;

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
    mapping(uint256 => mapping(IStats.Stat => uint256)) public stats;

    event CloneCreated(uint256 cloneId, address owner);

    constructor() {}

    function initialize(address _gameManager) public {
        require(!initialized, "Star Seekers: Already initialized");

        gameManager = GameManager(_gameManager);
        initialized = true;
    }

    /// @notice Gets cost of a clone in chain base token
    /// @return uint256 clone cost in chain base token based on chainlink feed price
    function cloneCostInBaseToken() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            gameManager.chainlinkFeed()
        );
        (, int256 purchaseTokenUsdPrice, , , ) = priceFeed.latestRoundData();
        uint256 denominator = uint256(purchaseTokenUsdPrice);

        return
            ((gameManager.cloneCost() * 1000000000000000000000) / denominator) *
            100000;
    }

    /// @notice Creates a new clone
    /// @dev gets the price of the chains base token from chainlink
    /// @param _uri json IPFS endpoint
    function create(string memory _uri) public payable notInMaintenance {
        require(
            gameManager.chainlinkFeed() != address(0),
            "Star Seekers: No chainlink feed set"
        );

        _handleReceivePayment(msg.sender);

        ICred cred = ICred(gameManager.contractAddresses("CRED"));

        uint256 newCloneId = IClone(gameManager.contractAddresses("Clone"))
            .create(msg.sender);

        CloneData memory newClone = CloneData({
            owner: msg.sender,
            for_sale: false,
            uri: _uri, // IPFS json endpoint
            price: 0,
            id: newCloneId
        });

        stats[newClone.id][IStats.Stat.charisma] = 5;
        stats[newClone.id][IStats.Stat.ingenuity] = 5;
        stats[newClone.id][IStats.Stat.intelligence] = 5;
        stats[newClone.id][IStats.Stat.spirit] = 5;
        stats[newClone.id][IStats.Stat.toughness] = 5;

        cloneData[newCloneId] = newClone;
        clonesOwnedByAddress[msg.sender].push(newClone.id);

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

    /// @notice get clones owned by an address
    /// @param _owner uint256 owner address
    /// @return array of clone ids
    function getClonesOwnedByAddress(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        return clonesOwnedByAddress[_owner];
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
        for (
            uint256 i = 0;
            i < clonesOwnedByAddress[cloneData[_cloneId].owner].length;
            i++
        ) {
            if (
                clonesOwnedByAddress[cloneData[_cloneId].owner][i] == _cloneId
            ) {
                clonesOwnedByAddress[cloneData[_cloneId].owner][
                    i
                ] = clonesOwnedByAddress[cloneData[_cloneId].owner][
                    clonesOwnedByAddress[cloneData[_cloneId].owner].length - 1
                ];
                clonesOwnedByAddress[cloneData[_cloneId].owner].pop();
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
    function changeSalesStatus(
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

    function _handleReceivePayment(address _buyer) private returns (bool) {
        uint256 cost = cloneCostInBaseToken();
        require(msg.value >= cost, "Star Seekers: Invalid payment amount");

        uint256 returnAmount = msg.value - cost;

        (bool sent, ) = payable(gameManager.federation()).call{value: cost}("");

        require(sent, "Star Seekers: Failed to send to federation");

        if (returnAmount > 0) {
            (sent, ) = _buyer.call{value: returnAmount}("");

            require(sent, "Star Seekers: Failed to return difference to buyer");
        }

        return true;
    }

    receive() external payable {}
}
