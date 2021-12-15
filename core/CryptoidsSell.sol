// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./common/PauseOwnable.sol";
import "../interface/ISellFactory.sol";

contract CryptoidsSell is PauseOwnable {
  address public ceo;
  uint256 public startBlock;

  uint256 public startId;
  uint256 public endId;
  uint32 public source;
  uint256 public price;

  uint256 public nextId;

  event Purchase(address indexed from, uint256 num, uint256 amount);

  function initialize(
    address _ceo, 
    uint256 _startBlock, 
    uint256 _startId, 
    uint256 _endId, 
    uint256 _price, 
    uint32 _source
  ) 
    external
    onlyOwner
  {
    require(_ceo != address(0));
    require(_startId < _endId);

    ceo = _ceo;
    startBlock = _startBlock;
    startId = _startId;
    endId = _endId;
    nextId = _startId;
    price = _price;
    source = _source;
  }

  function withdraw() external {
    payable(ceo).transfer(address(this).balance);
  }

  function buy(
    uint256 num
  ) 
    payable 
    external 
    whenNotPaused
  {
    require(block.number > startBlock, "not start");
    require(num > 0 && num <= 50, "num invalid");
    require(msg.value == price*num, "price invalid");
    require(nextId+num-1 < endId, "sell out");
    
    for (uint i=0; i<num; i++) {
      ISellFactory(owner()).buyProxy(nextId, msg.sender, source);
      nextId++;
    }

    emit Purchase(msg.sender, num, msg.value);
  }
}