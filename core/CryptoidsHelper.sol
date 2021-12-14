// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./common/PauseOwnable.sol";
import "../interface/ICryptoids.sol";

contract CryptoidsHelper is EIP712, PauseOwnable {
  using SafeERC20 for IERC20;

  address public cac;
  address public cgc;
  address public cpcore;

  uint256[7] public cacCostConfig;
  uint256[7] public cgcCostConfig;
  mapping(uint256 => uint256[2]) public parents;
  mapping(uint256 => uint256[]) public children;

  address public EVOLVE_ADMIN1;
  address public EVOLVE_ADMIN2;
  bytes32 public constant EVOLVE_TYPEHASH = keccak256('Evolve(uint256 id,uint256 genes1,uint256 genes2)');

  uint256 public nextId;
  uint256 constant MAX_BREED_TIMES = 7;

  event PapaBreedNew(uint256 indexed petId, address indexed owner, uint256 parent1, uint256 parent2, uint cac, uint cgc);
  event EvolveAdmin(address indexed admin1, address indexed admin2);
  event ChangeConfig(uint256[7] cacCostConfig, uint256[7] cgcCostConfig);
  event Evolve(uint256 indexed petId, address indexed signer);

  constructor(address _cac, address _cgc, address _cpcore, uint256 _startId) EIP712("Cryptoids Helper", "1") {
    cac = _cac;
    cgc = _cgc;
    cpcore = _cpcore;
    nextId = _startId;
  }

  function setEvolveAdmin(
    address _admin1,
    address _admin2
  ) 
    external 
    onlyOwner 
  {
    require(_admin1 != address(0) && _admin2 != address(0));
    EVOLVE_ADMIN1 = _admin1;
    EVOLVE_ADMIN2 = _admin2;
    emit EvolveAdmin(_admin1, _admin2);
  }

  function setCostConfig(
    uint256[7] memory _cacCostConfig,
    uint256[7] memory _cgcCostConfig
  )
    external
    onlyOwner
  {
    cacCostConfig = _cacCostConfig;
    cgcCostConfig = _cgcCostConfig;

    emit ChangeConfig(_cacCostConfig, _cgcCostConfig);
  }

  function withdraw(
    uint256 _cacAmount,
    uint256 _cgcAmount
  )
    external
    onlyOwner
  {
    IERC20(cac).transfer(owner(), _cacAmount);
    IERC20(cgc).transfer(owner(), _cgcAmount);
  }

  function cost1(
    uint256 _petId
  )
    external
    view
    returns (uint256 cacCost, uint256 cgcCost)
  {
    uint256 times = children[_petId].length;
    require(times < MAX_BREED_TIMES, "papa breed: reached the max times.");
    cacCost = cacCostConfig[times];
    cgcCost = cgcCostConfig[times];
  }

  function cost(
    uint256 _pet1,
    uint256 _pet2
  )
    external
    view
    returns (uint256 cacCost, uint256 cgcCost)
  {
    (uint256 cac1, uint256 cgc1) = this.cost1(_pet1);
    (uint256 cac2, uint256 cgc2) = this.cost1(_pet2);
    return (cac1+cac2, cgc1+cgc2);
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
    require(_pet1 != _pet2, "breed: same pet");
    require(ICryptoids(cpcore).ownerOf(_pet1) == msg.sender, "breed: not owner");
    require(ICryptoids(cpcore).ownerOf(_pet2) == msg.sender, "breed: not owner");
    (uint256 gene1, uint256 gene2, ) = ICryptoids(cpcore).getMetaInfo(_pet1);
    require(gene1 > 0 && gene2 > 0, "breed: not evoloved");
    (gene1, gene2, ) = ICryptoids(cpcore).getMetaInfo(_pet2);
    require(gene1 > 0 && gene2 > 0, "breed: not evoloved");

    (uint256 cacCost, uint256 cgcCost) = this.cost(_pet1, _pet2);
    IERC20(cac).safeTransferFrom(msg.sender, address(this), cacCost);
    IERC20(cgc).safeTransferFrom(msg.sender, address(this), cgcCost);

    uint256 babyId = nextId;
    // 0 means from breed
    ICryptoids(cpcore).spawnPAPA(babyId, msg.sender, 0);
    children[_pet1].push(babyId);
    children[_pet2].push(babyId);
    parents[babyId] = [_pet1, _pet2];
    nextId++;
    emit PapaBreedNew(babyId, msg.sender, _pet1, _pet2, cacCost, cgcCost);
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
    require(signatory == EVOLVE_ADMIN1 || signatory == EVOLVE_ADMIN2, "Signature valid.");
    _evolve(_petId, _genes1, _genes2);
    emit Evolve(_petId, signatory);
  }

  function evolveBySigner(
    uint256 _petId,
    uint256 _genes1,
    uint256 _genes2
  )
    external
    whenNotPaused
  {
    require(msg.sender == EVOLVE_ADMIN1 || msg.sender == EVOLVE_ADMIN2, "no access");
    _evolve(_petId, _genes1, _genes2);
    emit Evolve(_petId, msg.sender);
  }

  function _evolve(
    uint256 _petId,
    uint256 _genes1,
    uint256 _genes2
  ) 
    internal 
  {
    ICryptoids(cpcore).evolvePAPA(_petId, _genes1, _genes2);
  }
}