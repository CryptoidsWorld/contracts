// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CGC is ERC20("PAPA Game Coin", "CGC"), Ownable {
  uint256 public constant maxSupply = 10 ** 27;
  event GameCharge(address indexed from, uint256 amount);

  function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
    _mint(_to, _amount);
    require(totalSupply() <= maxSupply, "reach max supply");
    return true;
  }

  function charge(uint256 _amount) external {
    _burn(msg.sender, _amount);
    emit GameCharge(msg.sender, _amount);
  }
}