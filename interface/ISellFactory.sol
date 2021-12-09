// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISellFactory {
  function buyProxy(uint256 _petId, address _to, uint32 _source) external;
}