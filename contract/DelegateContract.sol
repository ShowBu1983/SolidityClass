// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract DelegateContract {
   address public owner;
   uint256 public id;
   uint256 public updatedAt;
   address public addressPlaceholder;
   uint256 public unreachableValueByTheMainContract;

   function setValues(uint256 _newId) public {
     id = _newId;
     unreachableValueByTheMainContract = 8;
   }
 }