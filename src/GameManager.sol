// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

contract GameManager {
    bool public maintenance = false;
    address public admin;

    mapping(string => address) public contractAddresses;
    mapping(address => bool) public isGameContract;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Star Seekers: Admin only");
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
}
