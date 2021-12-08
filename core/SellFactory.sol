// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "./PAPASell.sol";

contract SellFactory is Ownable {
  address public immutable papacore;
  address private immutable ceo;
  uint32 public nextSource = 1;
  bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");
  address[] public sellContracts;

  event Deploy(address indexed contractAddr, uint32 indexed source, uint256 startId, uint256 endId, uint256 price);

  constructor(address _papaCore, address _ceo) {
    papacore = _papaCore;
    ceo = _ceo;
  }

  function deploy(uint256 _startId, uint256 _endId, uint256 _price) external onlyOwner {
    bytes memory bytecode = type(PAPASell).creationCode;

    address addr;
    uint32 deploySource = nextSource;
		bytes32 salt = keccak256(abi.encodePacked(address(this), deploySource));

		assembly {
      addr := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    require(addr != address(0), "creat2 error");

    PAPASell(addr).initialize(ceo, papacore, _startId, _endId, _price, deploySource);
    IAccessControl(papacore).grantRole(MINTER_ROLE, addr);
    sellContracts.push(addr);
    nextSource++;

    emit Deploy(addr, deploySource, _startId, _endId, _price);
  }
}