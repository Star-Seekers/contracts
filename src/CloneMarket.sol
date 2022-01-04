// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IClone.sol";
import "./interfaces/IClones.sol";
import "./tokens/CRED.sol";

contract CloneMarket is UniversalData {
    uint256 public salesTax = 350;
    address public federation;

    event CloneListed(uint256 cloneId, uint256 price);
    event CloneListingCancelled(uint256 cloneId);

    constructor(address _gameManager, address _federation)
        UniversalData(_gameManager)
    {
        federation = _federation;
    }

    function list(uint256 _cloneId, uint256 _price)
        public
        onlyCloneOwner(msg.sender, _cloneId)
    {
        IClone cloneInstance = IClone(gameManager.contractAddresses("Clone"));
        require(
            cloneInstance.isApprovedForAll(msg.sender, address(this)),
            "Star Seekers: Market not approved"
        );
        IClones clonesInstance = IClones(
            gameManager.contractAddresses("Clones")
        );

        clonesInstance.changeSalesStatus(_cloneId, true, _price);

        emit CloneListed(_cloneId, _price);
    }

    function cancel(uint256 _cloneId)
        public
        onlyCloneOwner(msg.sender, _cloneId)
    {
        IClones clonesInstance = IClones(
            gameManager.contractAddresses("Clones")
        );

        clonesInstance.changeSalesStatus(_cloneId, false, 0);

        emit CloneListingCancelled(_cloneId);
    }

    function buy(uint256 _cloneId) public {
        IClones clonesInstance = IClones(
            gameManager.contractAddresses("Clones")
        );
        IClones.CloneData memory cloneData = clonesInstance.getCloneData(
            _cloneId
        );
        require(cloneData.for_sale == true, "Star Seeker: clone not for sale");

        Cred cred = Cred(gameManager.contractAddresses("CRED"));

        require(
            cred.balanceOf(msg.sender) >= cloneData.price,
            "Star Seekers: Not enough CRED"
        );
        require(
            cred.allowance(msg.sender, address(this)) >= cloneData.price,
            "Star Seekers: Improper allowance"
        );

        cred.transferFrom(msg.sender, address(this), cloneData.price);
        uint256 federationCut = cloneData.price * (salesTax / 100);
        uint256 sellerCut = cloneData.price -
            (cloneData.price * (salesTax / 100));

        cred.transfer(federation, federationCut);
        cred.transfer(cloneData.owner, sellerCut);

        clonesInstance.changeOwner(msg.sender, _cloneId);

        IClone cloneInstance = IClone(gameManager.contractAddresses("Clone"));
        cloneInstance.safeTransferFrom(
            cloneData.owner,
            address(this),
            _cloneId
        );
    }

    function updateFederation(address _newFederationAddress) public onlyAdmin {
        federation = _newFederationAddress;
    }
}
