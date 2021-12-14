// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./CryptoidsManager.sol";

contract Dependency {

  address public whitelistSetterAddress;

  CryptoidsSpawningManager public spawningManager;
  CryptoidsMarketplaceManager public marketplaceManager;
  CryptoidsGeneManager public geneManager;

  mapping (address => bool) public whitelistedSpawner;
  mapping (address => bool) public whitelistedGeneScientist;

  constructor() {
    whitelistSetterAddress = msg.sender;
  }

  modifier onlyWhitelistSetter() {
    require(msg.sender == whitelistSetterAddress);
    _;
  }

  modifier whenSpawningAllowed(address _owner) {
    require(
      address(spawningManager) == address(0) ||
        spawningManager.isSpawningAllowed(_owner)
    );
    _;
  }

  modifier whenTransferAllowed(address _from, address _to, uint256 _petId) {
    require(
      address(marketplaceManager) == address(0) ||
        marketplaceManager.isTransferAllowed(_from, _to, _petId)
    );
    _;
  }

  modifier whenEvolvementAllowed(uint256 _petId, uint256 _newGenes1, uint256 _newGenes2) {
    require(
      address(geneManager) == address(0) ||
        geneManager.isEvolvementAllowed(_petId, _newGenes1, _newGenes2)
    );
    _;
  }

  modifier onlySpawner() {
    require(whitelistedSpawner[msg.sender]);
    _;
  }

  modifier onlyGeneScientist() {
    require(whitelistedGeneScientist[msg.sender]);
    _;
  }

  function setWhitelistSetter(address _newSetter) external onlyWhitelistSetter {
    whitelistSetterAddress = _newSetter;
  }

  function setSpawningManager(address _manager) external onlyWhitelistSetter {
    spawningManager = CryptoidsSpawningManager(_manager);
  }

  function setMarketplaceManager(address _manager) external onlyWhitelistSetter {
    marketplaceManager = CryptoidsMarketplaceManager(_manager);
  }

  function setGeneManager(address _manager) external onlyWhitelistSetter {
    geneManager = CryptoidsGeneManager(_manager);
  }

  function setSpawner(address _spawner, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedSpawner[_spawner] != _whitelisted);
    whitelistedSpawner[_spawner] = _whitelisted;
  }

  function setGeneScientist(address _geneScientist, bool _whitelisted) external onlyWhitelistSetter {
    require(whitelistedGeneScientist[_geneScientist] != _whitelisted);
    whitelistedGeneScientist[_geneScientist] = _whitelisted;
  }
}
