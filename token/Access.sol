// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract Access is EIP712, Pausable {
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

  address private signer;
  mapping (address => uint8) private managers;
  modifier isManager {
    require(
      managers[msg.sender] == 1);
    _;
  }

  uint64 constant MIN_SIGNATURES = 2;
  uint64 public setSignerIdx;
  mapping (uint64 => SetSigner) public setSignerTransactions;

  struct SetSigner {
    address signer;

    uint256 end;
    uint8 signatureCount;
    mapping (address => uint8) signatures;
  }

  uint64 public replaceManagerIdx;
  mapping (uint64 => ReplaceManager) public replaceManagerTransactions;
  struct ReplaceManager {
    address old_manager;
    address new_manager;

    uint256 end;
    uint8 signatureCount;
    mapping (address => uint8) signatures;
  }

  event GameWithdraw(uint256 indexed orderId, address indexed recevier, uint256 amount);
  event ChangeSigner(address indexed signer);
  event ChangeManager(address indexed old_manager, address indexed new_manager);

  constructor(address _token, string memory _name, string memory _version, address[3] memory _managers) EIP712(_name, _version) {
    token = _token;
    for (uint i=0; i<_managers.length; i++) {
      managers[_managers[i]] = 1;
    }
  }

  function createSetSigner(
    address _newSigner
  )
    external
    isManager
  {
    SetSigner storage current = setSignerTransactions[setSignerIdx];
    require(current.end < block.timestamp, "setSigner: last vote is still alive.");

    setSignerIdx++;
    setSignerTransactions[setSignerIdx].signer = _newSigner;
    setSignerTransactions[setSignerIdx].end = block.timestamp + 1 hours;
  }

  function voteForSetSigner(
    uint64 _idx
  )
    external
    isManager
  {
    require(_idx == setSignerIdx, "vote has expired.");

    SetSigner storage vote = setSignerTransactions[_idx];
    require(vote.end < block.timestamp, "setSigner: last vote is still alive.");
    require(vote.signatures[msg.sender] != 1);

    vote.signatures[msg.sender] = 1;
    vote.signatureCount++;
    if(vote.signatureCount >= MIN_SIGNATURES){
      signer = vote.signer;
      vote.end = 0;
      emit ChangeSigner(vote.signer);
    }
  }

  function createReplaceManager(
    address _old_manager, 
    address _new_manager
  )
    external 
    isManager
  {
    require(managers[_old_manager] == 1);
    require(managers[_new_manager] == 0);
    require(msg.sender != _old_manager);
    require(_new_manager != _old_manager);
    
    ReplaceManager storage current = replaceManagerTransactions[replaceManagerIdx];
    require(current.end < block.timestamp, "replaceManager: last vote is still alive.");

    replaceManagerIdx++;
    replaceManagerTransactions[replaceManagerIdx].old_manager = _old_manager;
    replaceManagerTransactions[replaceManagerIdx].new_manager = _new_manager;
    replaceManagerTransactions[replaceManagerIdx].end = block.timestamp + 1 hours;
  }

  function voteForReplaceManager(
    uint64 _idx
  )
    external
    isManager
  {
    require(_idx == replaceManagerIdx, "vote has expired.");

    ReplaceManager storage vote = replaceManagerTransactions[_idx];
    require(vote.end < block.timestamp, "replaceManager: last vote is still alive.");
    require(vote.signatures[msg.sender] != 1);

    vote.signatures[msg.sender] = 1;
    vote.signatureCount++;
    if(vote.signatureCount >= MIN_SIGNATURES){
      managers[vote.old_manager] = 0;
      managers[vote.old_manager] = 1;
      vote.end = 0;
      emit ChangeManager(vote.old_manager, vote.new_manager);
    }
  }

  function setInterval(
    uint256 _interval, 
    uint256 _maxWithdraw
  ) 
    external
    isManager
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

  function maxTransferAmount() external view returns (uint256) {
    if (markStartTime + Interval > block.timestamp) {
      return IntervalMaxWithdraw.sub(accumulatedAmout);
    } else {
      return IntervalMaxWithdraw;
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
    require(signer == signatory, "Access: signature not valid.");
    _transfer(_receiver, _amount);
    orderStatus[_orderId] = true;
    emit GameWithdraw(_orderId, _receiver, _amount);
  }

  function pause() external isManager {
    _pause();
  }

  function unpause() external isManager {
    _unpause();
  }
}