//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract CryptoneX11 is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseTokenURI;
    uint256 private constant MAX_SUPPLY = 145;
    uint256 private constant UNIT_PRICE = 0.01 ether;
    mapping(uint256 => uint256) private m;

    constructor(string memory baseTokenURI) ERC721("CryptoneX11", "CX11") {
        setBaseTokenURI(baseTokenURI);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mint(address to) external payable returns (uint256) {
        require(totalSupply() + 1 <= MAX_SUPPLY, "!supply");
        require(msg.value >= UNIT_PRICE, "!ether");
        uint256 newItemId = shuffle();
        _safeMint(to, newItemId);
        _tokenIds.increment();
        return newItemId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function withdraw() external {
        uint256 balance = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = owner().call{value: balance}("");
        require(success, "!transfer");
    }

    function rand() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        totalSupply()
                    )
                )
            );
    }

    // Fisher-Yates shuffle, implemented with a sparse matrix
    function shuffle() private returns (uint256) {
        uint256 len = MAX_SUPPLY - totalSupply();
        return _shuffle(1 + (rand() % len), len);
    }

    function _shuffle(uint256 r, uint256 len) private returns (uint256) {
        uint256 _r;
        if (m[r] != 0) {
            if (r == len) return m[r];
            _r = m[r];
        } else {
            if (r == len) return r;
            _r = r;
        }
        if (m[len] != 0) {
            m[r] = m[len];
        } else {
            m[r] = len;
        }
        return _r;
    }
}
