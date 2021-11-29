// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interface/IPAPA.sol";
contract PAPASell is Ownable {
  address public immutable ceo;
  address public immutable papacore;
  uint256 public immutable startId;
  uint256 public immutable endId;
  uint32 public immutable source;
  uint256 public immutable price;

  uint256 public nextId;

  constructor(address _ceo, address _papacore, uint256 _startId, uint256 _endId, uint256 _price, uint32 _source) {
    require(_ceo != address(0));
    require(_startId < _endId);

    ceo = _ceo;
    papacore = _papacore;
    startId = _startId;
    endId = _endId;
    nextId = _startId;
    price = _price;
    source = _source;
  }

  function withdraw() external onlyOwner {
    payable(ceo).transfer(address(this).balance);
  }

  function buy(uint num) payable external {
    require(num > 0 && num <= 50);
    // cannot overflow.
    require(msg.value == price*num);
    require(nextId+num-1 <= endId);
    
    for (uint i=0; i<num; i++) {
      IPAPA(papacore).spawnPAPA(nextId, msg.sender, source);
      nextId++;
    }
  }
}