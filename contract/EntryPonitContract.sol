// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0;

contract EntryPointContract {
   address public owner = msg.sender;
   uint256 public id = 5;
   uint256 public updatedAt = block.timestamp;
   address public delegateContract;

   constructor(address _delegateContract) {
     delegateContract = _delegateContract;
   }

   function delegate(uint256 _newId) public returns(bool) {
     (bool success, ) =
     delegateContract.delegatecall(abi.encodeWithSignature("setValues(uint256)",
       _newId));
     return success;
   }

 }