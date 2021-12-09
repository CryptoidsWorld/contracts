// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

abstract contract PauseOwnable is Pausable, Ownable {
  function pause() 
    external 
    onlyOwner
  {
    _pause();
  }

  function unpause() 
    external
    onlyOwner
  {
    _unpause();
  }
}