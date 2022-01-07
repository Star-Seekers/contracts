// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

contract GameManager {
    bool public maintenance = false;
    address public admin;
    uint256 public salesTax = 350;
    uint256 public startingCred = 10000;
    address public federation;

    mapping(string => address) public contractAddresses;
    mapping(address => bool) public hasReceivedStartingCred;
    mapping(address => bool) public isGameContract;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Star Seekers: Admin only");
        _;
    }
    modifier onlyGameContract() {
        require(
            isGameContract[msg.sender],
            "Star Seekers: Not a game contract"
        );
        _;
    }

    constructor(address _admin) {
        require(_admin != address(0), "Star Seekers: Admin address required");
        admin = _admin;
    }

    function addContract(string memory _name, address _address)
        public
        onlyAdmin
    {
        contractAddresses[_name] = _address;
        isGameContract[_address] = true;
    }

    function changeAdmin(address _newAdmin) public onlyAdmin {
        admin = _newAdmin;
    }

    function removeContract(string memory _name) public onlyAdmin {
        address contractAddress = contractAddresses[_name];
        contractAddresses[_name] = address(0);
        isGameContract[contractAddress] = false;
    }

    function setMaintenance(bool _status) public onlyAdmin {
        maintenance = _status;
    }

    function setFederation(address _newFederationAddress) public onlyAdmin {
        federation = _newFederationAddress;
    }

    function setSalesTax(uint256 _amount) public onlyAdmin {
        salesTax = _amount;
    }

    function setStartingCred(uint256 _amount) public onlyAdmin {
        startingCred = _amount;
    }

    function updateHasReceivedStartingCred(address _player)
        external
        onlyGameContract
    {
        hasReceivedStartingCred[_player] = true;
    }
}
