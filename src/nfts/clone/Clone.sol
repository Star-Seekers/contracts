// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../interfaces/UniversalData.sol";
import "../../interfaces/ICloningFacility.sol";

contract Clone is ERC721, UniversalData {
    uint256 nextCloneId = 0;

    constructor(address _gameManager)
        ERC721("Star Seekers Clone", "SSCLONE")
        UniversalData(_gameManager)
    {}

    function create(address _owner)
        internal
        onlyGameContract
        returns (uint256)
    {
        uint256 cloneId = nextCloneId;

        _mint(_owner, cloneId);

        nextCloneId += 1;

        return cloneId;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return
            ICloningFacility(gameManager.contractAddresses("Clones"))
                .getCloneUri(_tokenId);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override notForSale(_tokenId) {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        ICloningFacility(gameManager.contractAddresses("Clones")).changeOwner(
            _to,
            _tokenId
        );

        _transfer(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override notForSale(_tokenId) {
        require(
            _isApprovedOrOwner(_msgSender(), _tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        ICloningFacility(gameManager.contractAddresses("Clones")).changeOwner(
            _to,
            _tokenId
        );

        _safeTransfer(_from, _to, _tokenId, _data);
    }
}
