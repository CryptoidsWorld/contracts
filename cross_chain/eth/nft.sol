// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PAPACore is ERC721Enumerable, Ownable {
  address public crossMiner;
  string public baseURI;

  modifier isCrossMiner {
    require(msg.sender == crossMiner);
    _;
  }

  constructor() ERC721("PAPA Master", "PAPA") {}

  function setCrossMiner(address _miner) external onlyOwner {
    crossMiner = _miner;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseURI = _uri;
  }

  function crossMint(address _to, uint256 _id) external isCrossMiner {
    if (_exists(_id)) {
      _transfer(ownerOf(_id), _to, _id);
    } else {
      _mint(_to, _id);
    }
  }

  function deposit(uint256 _id) external {
    require(ownerOf(_id) == msg.sender);
    _transfer(msg.sender, address(this), _id);
  }
}