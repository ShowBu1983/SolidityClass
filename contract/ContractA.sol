// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ContractB.sol";

contract ContractA{
    ContractB public contractB;
    constructor(address _contractBAddress){
        contractB = ContractB(_contractBAddress);
    }

    function setValueInContractB(uint256 _value) public{
        contractB.setValue(_value);
    }

    function getValueFromContractB() public view returns(uint256){
        return contractB.getValue();
    }

    receive() external payable { 
        
    }
}