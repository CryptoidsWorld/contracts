// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./CryptoidsSell.sol";
import "../interface/ICryptoids.sol";

contract SellFactory is Ownable {
  address public immutable cpcore;
  address public immutable ceo;
  uint32 public nextSource = 1;
  address[] public sellContracts;

  event Deploy(address indexed contractAddr, uint32 indexed source, uint256 startId, uint256 endId, uint256 price);

  constructor(address _cpcore, address _ceo) {
    cpcore = _cpcore;
    ceo = _ceo;
  }

  function pauseChild(uint32 _source) external onlyOwner {
    CryptoidsSell(sellContracts[_source-1]).pause();
  }

  function unpauseChild(uint32 _source) external onlyOwner {
    CryptoidsSell(sellContracts[_source-1]).unpause();
  }

  function buyProxy(
    uint256 _petId,
    address _to,
    uint32 _source
  )
    external
  {
    require(sellContracts[_source-1] == msg.sender, "buy: must call from child contract");
    ICryptoids(cpcore).spawnPAPA(_petId, _to, _source);
  }

  function deploy(
    uint256 _startBlock,
    uint256 _startId, 
    uint256 _endId, 
    uint256 _price
  ) external 
    onlyOwner 
  {
    bytes memory bytecode = type(CryptoidsSell).creationCode;

    address addr;
    uint32 deploySource = nextSource;
		bytes32 salt = keccak256(abi.encodePacked(address(this), deploySource));

		assembly {
      addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    require(addr != address(0), "creat2 error");

    CryptoidsSell(addr).initialize(ceo, _startBlock, _startId, _endId, _price, deploySource);
    sellContracts.push(addr);
    nextSource++;

    emit Deploy(addr, deploySource, _startId, _endId, _price);
  }
}