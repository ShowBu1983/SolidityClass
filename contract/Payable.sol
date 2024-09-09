// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract Payable{
    constructor(){

    }

    function deposit1() external payable {

    }

    function deposit2() external{

    }

    function withdraw() external {
        payable (msg.sender).transfer(address(this).balance);
    }

    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}