// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC721A.sol";
import "./MerkleProof.sol";

contract Selfie is Ownable, ERC721A {
  
    using Strings for uint256;

    bytes32 public rootHash;

    bool public isPublicSale = false;
    uint256 public publicSaleMaxMint = 2;
    uint256 public publicSalePrice = 0.09 ether;

    bool public isPreSale = true;
    uint256 public preSaleMaxMint = 1;
    uint256 public preSalePrice = 0.065 ether;

    uint256 public maxMintPerWallet = 3;

    bool public paused = false;

    uint256 public maxSupply = 2222;

    uint256 public amountForDevs = 100;

    mapping(address => bool) public whitelistPurchased;

  constructor() ERC721A("Selfie NFT", "Selfie") {}

  function preSaleMint(uint256 quantity, bytes32[] calldata proof) external payable {
    require( !paused, "Sale paused." );
    require( isPreSale && !isPublicSale, "PreSale not started." );

    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require( MerkleProof.verify(proof, rootHash, leaf), "Invalid proof");

    require( !whitelistPurchased[msg.sender], "Reached the maximum amount of whitelisted wallet." );
    require(
        quantity * publicSalePrice <= msg.value,
        "Not enough ether sent."
    );

    require(
      totalSupply() + quantity <= maxSupply,
      "Sale would exceed max supply."
    );

    require(
      numberMinted(msg.sender) + quantity <= preSaleMaxMint,
      "You mint too many."
    );

    _safeMint(msg.sender, quantity);
  }

  function startPreSale() public onlyOwner {
    isPreSale = true;
    isPublicSale = false;
  }

  function startPublicSale() public onlyOwner {
    isPreSale = false;
    isPublicSale = true;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRootHash(bytes32 _hash) public onlyOwner {
    rootHash = _hash;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

}