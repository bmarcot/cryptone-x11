//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract CryptoneX11 is ERC721URIStorage, Ownable, VRFConsumerBase {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseTokenURI;
    uint256 private constant MAX_SUPPLY = 145;
    uint256 private constant UNIT_PRICE = 4 ether;
    mapping(uint256 => uint256) private m;
    mapping(address => bool) private isMinting;
    mapping(bytes32 => address) private requesters;

    // Chainlink VRF
    bytes32 internal keyHash;
    uint256 internal fee;

    event RequestedRandomness(bytes32 requestId, address from);
    event FulfilledRandomness(bytes32 requestId);

    constructor(string memory baseTokenURI)
        ERC721("Cryptone X11", "CX11")
        VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1 // LINK Token
        )
    {
        setBaseTokenURI(baseTokenURI);
        keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
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
        for (uint256 i = 0; i < count; i++) doMint(to);
    }

    function doMint(address to) private {
        require(LINK.balanceOf(address(this)) >= fee, "!link");
        require(isMinting[msg.sender] == false, "!minting");
        isMinting[msg.sender] == true;
        bytes32 requestId = requestRandomness(keyHash, fee);
        emit RequestedRandomness(requestId, msg.sender);
        requesters[requestId] = to;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        emit FulfilledRandomness(requestId);
        uint256 newItemId = shuffle(randomness);
        _safeMint(requesters[requestId], newItemId);
        _tokenIds.increment();
        isMinting[msg.sender] = false;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseTokenURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
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
