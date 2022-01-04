//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CryptoneX11 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseTokenURI;

    uint256 public constant MAX_SUPPLY = 145;
    uint256 public constant UNIT_PRICE = 0.01 ether;

    constructor(string memory baseTokenURI) ERC721("CryptoneX11", "TON11") {
        setBaseTokenURI(baseTokenURI);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mint(address to) external payable returns (uint256) {
        uint256 newItemId = totalSupply() + 1;

        require(newItemId <= MAX_SUPPLY, "Max supply reached");
        require(msg.value >= UNIT_PRICE, "Not enough ether to purchase");
        _tokenIds.increment();
        _safeMint(to, newItemId);

        return newItemId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        (bool success, ) = owner().call{value: balance}("");
        require(success, "Transfer failed");
    }
}
