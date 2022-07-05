pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract Beerhound721 is ERC721URIStorage {

    address private _owner;
    address private _marketAddress;

    constructor (address marketplaceAddress) ERC721("Beerhound721", "BRHND721"){
        _owner = msg.sender;
        _marketAddress = marketplaceAddress;
    }

    function mint(address to, uint256 tokenId, string memory metadataUrl) public {
        require (_marketAddress == msg.sender, "Not allowed");
        require (to != address(0));
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, metadataUrl);
    }
}