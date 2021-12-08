// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CGC is ERC20("Cryptoids Game Coin", "CGC"), Ownable {
  event GameCharge(address indexed from, uint256 amount);

  function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
    _mint(_to, _amount);
    return true;
  }

  function charge(uint256 _amount) external {
    _burn(msg.sender, _amount);
    emit GameCharge(msg.sender, _amount);
  }
}