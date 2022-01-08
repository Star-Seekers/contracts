// SPDX-License-Identifier: GPLv3
pragma solidity ^0.8.0;

import "./interfaces/UniversalData.sol";
import "./interfaces/IClone.sol";
import "./interfaces/ICloningFacility.sol";
import "./tokens/CRED.sol";

contract CloneMarket is UniversalData {
    /// @notice emitted when a clone is listed on the market
    event CloneListed(uint256 cloneId, uint256 price);
    /// @notice emitted when a clone is removed from the market
    event CloneListingCancelled(uint256 cloneId);
    /// @notice emitted when a clone is purchased from the market
    event ClonePurchased(
        uint256 cloneId,
        address buyer,
        address seller,
        uint256 amount
    );

    constructor(address _gameManager) UniversalData(_gameManager) {}

    /// @notice Lists a clone on the clone market
    /// @dev only clone owner should be able to call this function for a given clone
    /// @param _cloneId the id of the clone to list for sale
    /// @param _price the price to list the clone for in CRED

    function list(uint256 _cloneId, uint256 _price)
        public
        onlyCloneOwner(msg.sender, _cloneId)
    {
        IClone cloneInstance = IClone(gameManager.contractAddresses("Clone"));
        require(
            cloneInstance.isApprovedForAll(msg.sender, address(this)),
            "Star Seekers: Market not approved"
        );
        ICloningFacility cloningFacility = ICloningFacility(
            gameManager.contractAddresses("CloningFacility")
        );

        cloningFacility.changeSalesStatus(_cloneId, true, _price);

        emit CloneListed(_cloneId, _price);
    }

    /// @notice Removes an active clone listing from the market
    /// @dev only clone owner should be able to call this function
    /// @param _cloneId the id of the clone that is listed for sale
    function cancel(uint256 _cloneId)
        public
        onlyCloneOwner(msg.sender, _cloneId)
    {
        ICloningFacility cloningFacility = ICloningFacility(
            gameManager.contractAddresses("CloningFacility")
        );

        cloningFacility.changeSalesStatus(_cloneId, false, 0);

        emit CloneListingCancelled(_cloneId);
    }

    /// @notice Buys a clone listed on the market
    /// @param _cloneId the id of the clone that is being purchased
    function buy(uint256 _cloneId) public {
        ICloningFacility cloningFacility = ICloningFacility(
            gameManager.contractAddresses("CloningFacility")
        );
        ICloningFacility.CloneData memory cloneData = cloningFacility
            .getCloneData(_cloneId);
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
        uint256 federationCut = cloneData.price *
            (gameManager.salesTax() / 100);
        uint256 sellerCut = cloneData.price - federationCut;

        cred.transfer(gameManager.federation(), federationCut);
        cred.transfer(cloneData.owner, sellerCut);

        IClone cloneInstance = IClone(gameManager.contractAddresses("Clone"));
        cloneInstance.safeTransferFrom(cloneData.owner, msg.sender, _cloneId);

        emit ClonePurchased(
            _cloneId,
            msg.sender,
            cloneData.owner,
            cloneData.price
        );
    }
}
