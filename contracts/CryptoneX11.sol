//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract CryptoneX11 is ERC721URIStorage, Ownable, VRFConsumerBase {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 private constant MAX_SUPPLY = 145;
    uint256 private constant UNIT_PRICE = 0.01 ether;
    mapping(uint256 => uint256) private m;
    mapping(address => bool) private isMinting;
    mapping(bytes32 => address) private requesters;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;

    constructor()
        ERC721("CryptoneX11", "CX11")
        VRFConsumerBase(
            0x8C7382F9D8f56b33781fE506E897a4F1e2d17255,
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        )
    {
        keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
        fee = 0.0001 * 10**18;
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mint(address to) external payable {
        require(totalSupply() + 1 <= MAX_SUPPLY, "!supply");
        require(msg.value >= UNIT_PRICE, "!ether");
        doMint(to);
    }

    function ownerMint(address to, uint256 count) external onlyOwner {
        require(totalSupply() + count <= MAX_SUPPLY, "!supply");
        for (uint256 i = 0; i < count; count++) doMint(to);
    }

    function doMint(address to) private {
        require(LINK.balanceOf(address(this)) >= fee, "!link");
        require(isMinting[msg.sender] == false, "!minting");
        isMinting[msg.sender] == true;
        bytes32 requestId = requestRandomness(keyHash, fee);
        requesters[requestId] = to;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 newItemId = shuffle(randomness);
        _safeMint(requesters[requestId], newItemId);
        _tokenIds.increment();
        isMinting[msg.sender] = false;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmWrzgPNvKqRAW96hztUwc6ZHsutkri4GwThzxvMYbNLMm/";
    }

    // Fisher-Yates shuffle, implemented with a sparse matrix
    function shuffle(uint256 randomness) private returns (uint256) {
        uint256 len = MAX_SUPPLY - totalSupply();
        return _shuffle(1 + (randomness % len), len);
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

    function withdraw() external {
        uint256 balance = address(this).balance;
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = owner().call{value: balance}("");
        require(success, "!transfer");
    }
}
