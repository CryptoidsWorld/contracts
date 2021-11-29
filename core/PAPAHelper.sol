// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "../interface/IPAPA.sol";

contract PAPAHelper is EIP712, Ownable, Pausable {
  using SafeERC20 for IERC20;

  address public pac;
  address public pgc;
  address public papacore;

  uint256[7] public pacCostConfig;
  uint256[7] public pgcCostConfig;
  mapping(uint256 => uint256[2]) public parents;
  mapping(uint256 => uint256[]) public children;

  address public EVOLVE_ADMIN;
  bytes32 public constant EVOLVE_TYPEHASH = keccak256('Evolve(uint256 id,uint256 genes1,uint256 genes2)');
  bytes32 public constant EVOLVE_ROLE = keccak256("EVOLVE_ROLE");

  uint256 public nextId;
  uint256 constant MAX_BREED_TIMES = 7;

  event PapaBreedNew(uint256 indexed petId, address indexed owner, uint256 parent1, uint256 parent2);
  event EvolveAdmin(address indexed admin);

  constructor(address _pac, address _pgc, address _papacore, uint256 _startId) EIP712("PAPA Helper", "1") {
    pac = _pac;
    pgc = _pgc;
    papacore = _papacore;
    nextId = _startId;
  }

  function setEvolveAdmin(address _admin) external onlyOwner {
    require(_admin != address(0));
    EVOLVE_ADMIN = _admin;
    emit EvolveAdmin(_admin);
  }

  function setCostConfig(
    uint256[7] memory _pacCostConfig,
    uint256[7] memory _pgcCostConfig
  )
    external
    onlyOwner
  {
    pacCostConfig = _pacCostConfig;
    pgcCostConfig = _pgcCostConfig;
  }

  function cost1(
    uint256 _petId
  )
    external
    view
    returns (uint256 pacCost, uint256 pgcCost)
  {
    uint256 times = children[_petId].length;
    require(times < MAX_BREED_TIMES, "papa breed: reached the max times.");
    pacCost = pacCostConfig[times];
    pgcCost = pgcCostConfig[times];
  }

  function cost(
    uint256 _pet1,
    uint256 _pet2
  )
    external
    view
    returns (uint256 pacCost, uint256 pgcCost)
  {
    (uint256 pac1, uint256 pgc1) = this.cost1(_pet1);
    (uint256 pac2, uint256 pgc2) = this.cost1(_pet2);
    return (pac1+pac2, pgc1+pgc2);
  }

  function breedCount(
    uint256 _petId
  )
    external
    view
    returns (uint256)
  {
    return children[_petId].length;
  }

  function breed(
    uint256 _pet1,
    uint256 _pet2
  )
    external
    whenNotPaused
  {
    require(_pet1 != _pet2);
    require(IPAPA(papacore).ownerOf(_pet1) == msg.sender);
    require(IPAPA(papacore).ownerOf(_pet2) == msg.sender);

    (uint256 pacCost, uint256 pgcCost) = this.cost(_pet1, _pet2);
    IERC20(pac).safeTransferFrom(msg.sender, address(this), pacCost);
    IERC20(pgc).safeTransferFrom(msg.sender, address(this), pgcCost);

    uint256 babyId = nextId;
    // 0 means from breed
    IPAPA(papacore).spawnPAPA(babyId, msg.sender, 0);
    children[_pet1].push(babyId);
    children[_pet2].push(babyId);
    parents[babyId] = [_pet1, _pet2];
    nextId++;
    emit PapaBreedNew(babyId, msg.sender, _pet1, _pet2);
  }

  function evolve(
    uint256 _petId,
    uint256 _genes1,
    uint256 _genes2,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
    whenNotPaused
  {
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
      EVOLVE_TYPEHASH,
      _petId,
      _genes1,
      _genes2
    )));
    address signatory = ECDSA.recover(digest, v, r, s);
    require(signatory == EVOLVE_ADMIN, "Signature valid.");
    _evolve(_petId, _genes1, _genes2);
  }

  function evolveWithSigner(
    uint256 _petId,
    uint256 _genes1,
    uint256 _genes2
  )
    external
    onlyOwner
    whenNotPaused
  {
    require(msg.sender == EVOLVE_ADMIN);
    _evolve(_petId, _genes1, _genes2);
  }

  function _evolve(
    uint256 _petId,
    uint256 _genes1,
    uint256 _genes2
  ) 
    internal 
  {
    IPAPA(papacore).evolvePAPA(_petId, _genes1, _genes2);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}