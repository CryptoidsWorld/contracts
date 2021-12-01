// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PAPACore is ERC721Enumerable, AccessControl, Ownable, Pausable {
  struct papaMeta {
    uint256 genes1;
    uint256 genes2;
    uint256 bornAt;
  }

  address public crossMiner;
  modifier isCrossMiner {
    require(msg.sender == crossMiner);
    _;
  }

  mapping(uint256 => papaMeta) public papaes;
  uint256 public immutable maxSupply;
  string public baseURI;

  bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 constant EVOLVE_ROLE = keccak256("EVOLVE_ROLE");

  event PAPASpawned(uint256 indexed petId, address indexed owner, uint32 indexed source);
  event PAPAEvolved(uint256 indexed petId, uint256 genes1, uint256 genes2);

  constructor() ERC721("PAPA Master", "PAPA") {
    maxSupply = 1000000;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function supportsInterface(
    bytes4 interfaceId
  ) 
    public 
    view 
    virtual 
    override(ERC721Enumerable, AccessControl) 
    returns (bool) 
  {
    return super.supportsInterface(interfaceId);
  }

  function spawnPAPA(
    uint256 _petId,
    address _to,
    uint32 _source
  )
    external
    onlyRole(MINTER_ROLE)
    whenNotPaused
  {
    // source eq 0 means called from breed contract.
    require(totalSupply() < maxSupply, "NFT: Total supply reached");
    _mint(_to, _petId);
    papaes[_petId] = papaMeta(0, 0, block.timestamp);
    emit PAPASpawned(_petId, _to, _source);
  }

  function evolvePAPA(
    uint256 _petId,
    uint256 _genes1,
    uint256 _genes2
  )
    external
    onlyRole(EVOLVE_ROLE)
    whenNotPaused
  {
    require(_exists(_petId), "papa: pet does not exists!");
    papaMeta storage papa = papaes[_petId];
    papa.genes1 = _genes1;
    papa.genes2 = _genes2;
    emit PAPAEvolved(_petId, _genes1, _genes2);
  }

  function papaesOfOwnerBySize(
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

  function getMetaInfo(uint256 _petId) external view returns (uint256, uint256, uint256) {
    papaMeta memory papa = papaes[_petId];
    return (papa.genes1, papa.genes2, papa.bornAt);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _uri) external onlyOwner whenNotPaused {
    baseURI = _uri;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function setCrossMiner(address _miner) external onlyOwner {
    crossMiner = _miner;
  }

  function crossMint(address _to, uint256 _id) external isCrossMiner {
    require(_exists(_id));
    _transfer(ownerOf(_id), _to, _id);
  }

  function deposit(uint256 _id) external {
    require(ownerOf(_id) == msg.sender);
    _transfer(msg.sender, address(this), _id);
  }
}