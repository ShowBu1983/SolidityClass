// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Callee{
    function splitEther(address payable addr1, address payable addr2) public payable {
        require(msg.value % 2 ==0, "Even value required.");
        addr1.transfer(msg.value / 2);
        addr2.transfer(msg.value / 2);
    }
}