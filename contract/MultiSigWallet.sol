// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
多签钱包DEMO
*/
contract MultiSigWallet{
    address[] public owners; //状态变量：声明在函数外，默认存储在区块链上（不需要加上数据位置）
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

/**
*以太坊的事件（Event）机制是一种在智能合约中定义和触发事件的方式，用于实现合约与外部世界的通信和提供交易的可追溯性。
*事件机制可以让智能合约在特定条件满足时触发事件，并将相关信息记录在以太坊区块链上的日志中。
*/
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

    //检测MSG sender 是否是钱包所有人之一
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner");
        _;
    }

    //输入的交易序列号不能超过交易的总数
    modifier txExists(uint256 _txId){
        require(_txId < transactions.length, "tx doesnt exist");
        _;
    }

    //检查该交易是否已经被批准过
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

        for(uint256 i = 0; i < _owners.length; i ++){
            address owner = _owners[i];
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
        //目标合约地址.call{value:发送ETH数额， gas：gas数额}(二进制编码)
        //abi.encodeWithSignature("函数签名", 逗号分隔具体参数)
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