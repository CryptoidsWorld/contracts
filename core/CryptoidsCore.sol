// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./common/PauseOwnable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoidsCore is PauseOwnable, ERC721Enumerable, ERC721Holder {
  struct cryptoid {
    uint256 genes1;
    uint256 genes2;
    uint256 bornAt;
  }

  string public baseURI;
  uint256 public immutable maxSupply;
  mapping(uint256 => cryptoid) public cps;

  address public MINTER_ADMIN;
  address public EVOLVE_ADMIN;

  event NewEvolveAdmin(address indexed admin);
  event NewMinterAdmin(address indexed admin);
  event PAPAEvolved(uint256 indexed petId, uint256 genes1, uint256 genes2);
  event PAPASpawned(uint256 indexed petId, address indexed owner, uint32 indexed source);

  constructor() ERC721("Cryptoids Master", "CP") {
    maxSupply = 1000000;
  }

  function setMinterAdmin(
    address _admin
  )
    external 
    onlyOwner
  {
    MINTER_ADMIN = _admin;
    emit NewMinterAdmin(_admin);
  }

  function spawnPAPA(
    uint256 _petId,
    address _to,
    uint32 _source
  )
    external
    whenNotPaused
  {
    require(msg.sender == MINTER_ADMIN, "Cryptoids: caller is not the minter");
    require(totalSupply() < maxSupply, "Cryptoids: Total supply reached");
    _mint(_to, _petId);
    cps[_petId] = cryptoid(0, 0, block.timestamp);
    emit PAPASpawned(_petId, _to, _source);
  }

  function setEvolveAdmin(
    address _admin
  )
    external 
    onlyOwner
  {
    EVOLVE_ADMIN = _admin;
    emit NewEvolveAdmin(_admin);
  }

  function evolvePAPA(
    uint256 _petId,
    uint256 _genes1,
    uint256 _genes2
  )
    external
    whenNotPaused
  {
    require(msg.sender == EVOLVE_ADMIN, "Cryptoids: No access");
    require(_exists(_petId), "Cryptoids: Pet does not exists");
    cryptoid storage cp = cps[_petId];
    require(cp.genes1 == 0 && cp.genes2 ==0, "Cryptoids: Already evolve");
    cp.genes1 = _genes1;
    cp.genes2 = _genes2;
    emit PAPAEvolved(_petId, _genes1, _genes2);
  }

  function cpsOfOwnerBySize(
    address _owner,
    uint256 _cursor,
    uint256 _size
  )
    external
    view
    returns(uint256 []memory, uint256)
  {
    uint256 length = _size;
    if (length > balanceOf(_owner) - _cursor) {
      length = balanceOf(_owner) - _cursor;
    }

    uint256 [] memory values = new uint256[](length);
    for (uint256 i=0; i < length; i++) {
      values[i] = tokenOfOwnerByIndex(_owner, _cursor + i);
    }

    return (values, _cursor + length);
  }

  function getMetaInfo(
    uint256 _petId
  ) 
    external 
    view 
    returns (uint256, uint256, uint256) 
  {
    cryptoid memory cp = cps[_petId];
    return (cp.genes1, cp.genes2, cp.bornAt);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(
    string memory _uri
  ) external 
    onlyOwner
    whenNotPaused 
  {
    baseURI = _uri;
  }
}