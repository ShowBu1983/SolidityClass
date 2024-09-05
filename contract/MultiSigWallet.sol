// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiSigWallet{
    address[] public owners;
    mapping(address=>bool) public isOwner;
    //定义 需要多少人以上完成一笔交易
    uint256 public required;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address=>bool)) public approved;

    //往多钱包里存钱
    event Deposit(address indexed sender, uint256 amount);
    //提交交易txID = transaction ID 交易的序号
    event Submit(uint256 indexed txId);
    //当有人提交交易时，允许交易
    event Approve(address indexed owner, uint256 indexed txId);
    //撤销交易
    event Revoke(address indexed owner, uint256 indexed txId);
    //执行交易
    event Execute(uint256 indexed txId);

    //检测MSG sender 是否时钱包所有人之一
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    //输入的交易序列号不能超过交易的总数
    modifier txExists(uint256 _txId){
        require(_txId < transactions.length, "tx doesnt exist");
        _;
    }

    //检查该交易是否已经被调用过
    modifier notApproved(uint256 _txId){
        require(approved[_txId][msg.sender], "tx already approved");
        _;
    }

    //检查该笔交易是否已经执行了
    modifier notExecuted(uint256 _txId){
        require(!transactions[_txId].executed, "tx is executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _required){
        require(_owners.length > 0, "owner required");
        require(_required > 0 && _required <= owners.length, "ivalid required number of owners");

        for(uint256 index = 0; index < _owners.length; index ++){
            address owner = _owners[index];
            //保证地址不为0x000。。.000
            require(owner != address(0), "invalid owner");
            //保证没有重复的地址
            require(!isOwner[owner], "owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }
        //定义需要的人数
        required = _required;
    }

    function getBalance() external view returns(uint256){
        return address(this).balance;
    }

    //定义一个 receive函数，让我们的合约可以收款，每当有地址往里面转以太坊的时候，就排除一个Deposit事件
    receive() external payable { 
        emit Deposit(msg.sender, msg.value);
    }

    // 用于提交一笔交易
    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns(uint256)
    {
        transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false}));
        emit Submit(transactions.length - 1);
        return transactions.length - 1;
    }

    //同意某笔交易
    function approve(uint256 _txId)
        external 
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    //执行某笔交易
    function execute(uint256 _txId)
        external 
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        require(getApproveCount(_txId) >= required, "not enough people agree this transaction");
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        // (bool suc, ) = transaction.to.call{value:transaction.value}(transaction.data);
        // require(suc, "tx failed");
        payable(transaction.to).transfer(transaction.value);
        emit Execute(_txId);
    }

    //统计有多少人
    function getApproveCount(uint256 _txId) public view returns(uint256 count){
        for(uint256 i = 0; i < owners.length; i ++){
            if(approved[_txId][owners[i]]){
                count += 1;
            }
        }
    }

    function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId){
        require(approved[_txId][msg.sender], "tx not approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}