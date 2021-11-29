// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Access is EIP712, AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  uint256 public markStartTime;
  uint256 public accumulatedAmout;

  // below can be setting.
  uint256 public IntervalMaxWithdraw;
  uint256 public Interval;

  address public immutable token;
  mapping(uint256 => bool) public orderStatus;
  bytes32 public constant MINT_TYPEHASH = keccak256('Mint(address recevier,uint256 amount,uint256 orderId)');
  bytes32 public constant CFO_ROLE = keccak256("CFO_ROLE");
  bytes32 public constant CEO_ROLE = keccak256("CEO_ROLE");

  event GameWithdraw(uint256 indexed orderId, address indexed recevier, uint256 amount);

  constructor(address _token, string memory _name, string memory _version) EIP712(_name, _version) {
    token = _token;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  function setInterval(
    uint256 _interval, 
    uint256 _maxWithdraw
  ) 
    external onlyRole(CEO_ROLE) 
  {
    Interval = _interval;
    IntervalMaxWithdraw = _maxWithdraw;
  }

  // For the sake of safety, only the specified money is allowed to be transferred in each interval
  function _transfer(address _to, uint256 _amount) internal {
    if (markStartTime + Interval > block.timestamp) {
      uint256 tempAmount = accumulatedAmout.add(_amount);
      require(tempAmount <= IntervalMaxWithdraw, "Access: transfer amount over.");
      IERC20(token).safeTransfer(_to, _amount);
      accumulatedAmout = tempAmount;
    } else {
      require(_amount <= IntervalMaxWithdraw, "Access: transfer amount over.");
      IERC20(token).safeTransfer(_to, _amount);
      accumulatedAmout = _amount;
      markStartTime = block.timestamp;
      accumulatedAmout = _amount;
    }
  }

  function mintBySignature(
    address _receiver,
    uint256 _amount,
    uint256 _orderId,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
  {
    require(!orderStatus[_orderId], "Access: order invalid.");
    bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
      MINT_TYPEHASH,
      _receiver,
      _amount,
      _orderId
    )));
    address signatory = ECDSA.recover(digest, v, r, s);
    require(hasRole(CFO_ROLE, signatory), "Access: signature not valid.");
    _transfer(_receiver, _amount);
    orderStatus[_orderId] = true;
    emit GameWithdraw(_orderId, _receiver, _amount);
  }
}