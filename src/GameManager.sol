// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

contract GameManager {
    bool internal initialized = false;

    address public admin;
    address public chainlinkFeed;
    address payable public federation;
    bool public maintenance;
    uint256 public cloneCost; /// usd price
    uint256 public salesTax; /// percentage
    uint256 public startingCred;

    /// @notice contractAddresses["ContractName"] => contractAddress
    mapping(string => address) public contractAddresses;
    /// @notice hasReceivedStartingCred[playerAddress] => boolean
    mapping(address => bool) public hasReceivedStartingCred;
    /// @notice isGameContract[contractAddress] => boolean
    mapping(address => bool) public isGameContract;

    /// @notice insures only the admin address can make these changes
    modifier onlyAdmin() {
        require(msg.sender == admin, "Star Seekers: Admin only");
        _;
    }
    /// @notice insures only an address registered as a game contract can make these changes
    modifier onlyGameContract() {
        require(
            isGameContract[msg.sender],
            "Star Seekers: Not a game contract"
        );
        _;
    }

    event AddContract(string name, address contractAddress);
    event AdminUpdated(address oldAdmin, address newAdmin);
    event RemoveContract(string name, address contractAddress);
    event ChainlinkFeedUpdated(address feed);
    event MaintenanceUpdated(bool status);
    event FederationUpdated(address federation);
    event SalesTaxUpdated(uint256 amount);
    event StartingCredUpdated(uint256 amount);
    event ReceivedStartingCred(address player);

    function initialize(
        address _admin,
        address _chainlinkFeed,
        address payable _federation
    ) public {
        require(!initialized, "Star Seekers: Already initialized");
        require(_admin != address(0), "Star Seekers: Admin address required");
        require(
            _chainlinkFeed != address(0),
            "Star Seekers: Chainlink Feed address required"
        );
        require(
            _federation != address(0),
            "Star Seekers: Federation address required"
        );
        admin = _admin;

        chainlinkFeed = _chainlinkFeed;
        cloneCost = 50;
        federation = _federation;
        initialized = true;
        maintenance = false;
        salesTax = 5;
        startingCred = 10000;
    }

    /// @notice adds a contract as a registered game contract
    /// @dev only the admin address should be able to make this change
    /// @param _name contract name used when calling getters.
    /// @param _address the address of the contract we're adding to the database
    function addContract(string memory _name, address _address)
        public
        onlyAdmin
    {
        contractAddresses[_name] = _address;
        isGameContract[_address] = true;

        emit AddContract(_name, _address);
    }

    /// @notice changes the admin
    /// @dev only the admin address should be able to make this change
    /// @param _newAdmin new admin address
    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;

        emit AdminUpdated(msg.sender, _newAdmin);
    }

    /// @notice removes a contract from the database by name
    /// @dev only the admin address should be able to make this change
    /// @param _name contract name that will be removed from database
    function removeContract(string memory _name) public onlyAdmin {
        address contractAddress = contractAddresses[_name];
        require(
            isGameContract[contractAddress],
            "Star Seekers: Not a game contract"
        );

        contractAddresses[_name] = address(0);
        isGameContract[contractAddress] = false;

        emit RemoveContract(_name, contractAddress);
    }

    /// @notice changes the feed for chainlink
    /// @dev only the admin address should be able to make this change
    /// @param _feedContract address of the chainlink feed contract
    function setChainlinkFeed(address _feedContract) public onlyAdmin {
        chainlinkFeed = _feedContract;

        emit ChainlinkFeedUpdated(_feedContract);
    }

    /// @notice changes the maintenance status
    /// @dev only the admin address should be able to make this change
    /// @param _status boolean to set maintenance
    function setMaintenance(bool _status) public onlyAdmin {
        maintenance = _status;

        emit MaintenanceUpdated(_status);
    }

    /// @notice changes federation address
    /// @dev only the admin address should be able to make this change
    /// @param _newFederationAddress new federation address
    function setFederation(address payable _newFederationAddress)
        public
        onlyAdmin
    {
        federation = _newFederationAddress;

        emit FederationUpdated(federation);
    }

    /// @notice change sales tax
    /// @dev only the admin address should be able to make this change
    /// @param _amount amount sales tax will be updated to
    function setSalesTax(uint256 _amount) public onlyAdmin {
        salesTax = _amount;

        emit SalesTaxUpdated(_amount);
    }

    /// @notice change starting cred amount
    /// @dev only the admin address should be able to make this change
    /// @param _amount new starting cred amount
    function setStartingCred(uint256 _amount) public onlyAdmin {
        startingCred = _amount;

        emit StartingCredUpdated(_amount);
    }

    /// @notice sets boolean to true when a wallet has received starting cred for creating a new clone
    /// @dev only a game contract should be able to call this function. A player can only receive CRED
    /// for the first clone created with that wallet.
    /// @param _player address to update
    function updateHasReceivedStartingCred(address _player)
        external
        onlyGameContract
    {
        hasReceivedStartingCred[_player] = true;

        emit ReceivedStartingCred(_player);
    }
}
