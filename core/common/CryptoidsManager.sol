// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface CryptoidsSpawningManager {
	function isSpawningAllowed(address _owner) external returns (bool);
}

interface CryptoidsMarketplaceManager {
  function isTransferAllowed(address _from, address _to, uint256 _petId) external returns (bool);
}

interface CryptoidsGeneManager {
  function isEvolvementAllowed(uint256 _petId, uint256 _newGenes1, uint256 _newGenes2) external returns (bool);
}
