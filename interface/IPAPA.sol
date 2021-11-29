// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPAPA is IERC721 {
  function spawnPAPA(uint256 _petId, address _to, uint32 _source) external;
  function evolvePAPA(uint256 _petId, uint256 _genes1, uint256 _genes2) external; 
  function getMetaInfo(uint256 _petId) external view returns (uint256, uint256, uint256);
}