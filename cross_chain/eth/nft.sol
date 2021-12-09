// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../core/common/CrossNFT.sol";

contract PAPACoreEth is CrossNFT {
  string public baseURI;

  constructor() ERC721("Cryptoids Master", "PAPA") {}

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _uri) external onlyOwner {
    baseURI = _uri;
  }
}