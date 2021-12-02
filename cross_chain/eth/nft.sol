// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract PAPACoreEth is ERC721Enumerable, Ownable, Pausable, ERC721Holder {
  address public crossMiner;
  string public baseURI;

  event NewCrossMiner(address indexed newCrossMiner);
  event CrossChain(address indexed receiver, uint256 indexed petId);
  event DepositCross(address indexed sender, uint256 indexed petId);

  modifier isCrossMiner {
    require(msg.sender == crossMiner);
    _;
  }

  constructor() ERC721("PAPA Master", "PAPA") {}

  function setCrossMiner(address _miner) external onlyOwner {
    crossMiner = _miner;
    emit NewCrossMiner(_miner);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseURI = _uri;
  }

  function crossMint(
    address _to, 
    uint256 _id
  ) 
    external 
    isCrossMiner 
  {
    if (_exists(_id)) {
      _transfer(ownerOf(_id), _to, _id);
    } else {
      _mint(_to, _id);
    }
    emit CrossChain(_to, _id);
  }

  function depositCross(
    uint256 _id
  ) 
    external 
  {
    require(ownerOf(_id) == msg.sender);
    _transfer(msg.sender, address(this), _id);
    emit DepositCross(msg.sender, _id);
  }

  function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
  ) 
    internal 
    override
  {
    require(!paused(), "Pausable: paused");
    super._beforeTokenTransfer(from, to, tokenId);
  }
}