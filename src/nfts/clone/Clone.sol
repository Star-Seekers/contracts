// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../../interfaces/UniversalData.sol";
import "../../interfaces/IClones.sol";

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
            IClones(gameManager.contractAddresses("Clones")).getCloneUri(
                _tokenId
            );
    }
}
