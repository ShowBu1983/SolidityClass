// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

contract EtherStore {

    uint256 public withdrawalLimit = 1 ether;
    mapping(address => uint256) public lastWithdrawTime;
    mapping(address => uint256) public balances;

    uint256 public balance;

    constructor() payable {
        balance = address(this).balance;
    }
    
    function depositFunds() public payable {
        balances[msg.sender] += msg.value;
    }
    
    function withdrawFunds (uint256 _weiToWithdraw) public {
        require(balances[msg.sender] >= _weiToWithdraw);
        // limit the withdrawal
        require(_weiToWithdraw <= withdrawalLimit);
        // limit the time allowed to withdraw
        require(block.timestamp >= lastWithdrawTime[msg.sender] + 1 weeks);
        // (bool succ, ) = payable(msg.sender).call{value:_weiToWithdraw}("");
        // require(succ, "tx failed");
        payable(msg.sender).transfer(_weiToWithdraw);
        balances[msg.sender] -= _weiToWithdraw;
        lastWithdrawTime[msg.sender] = block.timestamp;
    }

    receive() external payable { 
        balance += msg.value;
    }

    function sendEtherToSelf(uint256 amount) public {
        require(amount < balance, "Insufficient balance");
        (bool succ, ) = payable(address(this)).call{value:amount}("");
        require(succ, "Trans failed");
        balance -= amount;
    }
 }