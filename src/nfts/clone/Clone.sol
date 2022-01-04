// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../interfaces/UniversalData.sol";
import "../../Clones.sol";

contract Clone is ERC721, UniversalData {
    uint256 cloneIds = 0;

    constructor(address _gameManager)
        ERC721("Star Seekers Clone", "SSCLONE")
        UniversalData(_gameManager)
    {}

    function create(address _owner, string memory _uri)
        internal
        onlyGameContract
        returns (uint256)
    {
        uint256 newCloneId = cloneIds;
        _mint(_owner, newCloneId);

        cloneIds += 1;

        return newCloneId;
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
        Clones clonesInstance = Clones(gameManager.contractAddresses("Clones"));
        (, string memory uri, ) = clonesInstance.cloneData(_tokenId);

        return uri;
    }
}
