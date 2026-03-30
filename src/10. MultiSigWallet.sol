// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract MultiSigWalletOptimized {
    error NotOwner();
    error TxDoesNotExist();
    error TxAlreadyConfirmed();
    error TxAlreadyExecuted();
    error OwnersRequired();
    error InvalidRequired();
    error InvalidOwner();

    // O(1) owner lookup instead of O(n) array scan
    mapping(address => bool) private isOwnerMap;
    address[] public owners;
    uint256 public required;

    // Packed struct: slot0 = destination(20) + executed(1) + confirmationCount(1), slot1 = value(32)
    struct Transaction {
        address destination;
        bool executed;
        uint8 confirmationCount;
        uint256 value;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    event Deposit(address indexed sender, uint256 value);
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed owner, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);

    modifier onlyOwner() {
        if (!isOwnerMap[msg.sender]) revert NotOwner();
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        uint256 len = _owners.length;
        if (len == 0) revert OwnersRequired();
        if (_required == 0 || _required > len) revert InvalidRequired();

        for (uint256 i; i < len;) {
            address owner = _owners[i];
            if (owner == address(0)) revert InvalidOwner();
            owners.push(owner);
            isOwnerMap[owner] = true;
            unchecked {
                ++i;
            }
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address destination, uint256 value) public onlyOwner {
        uint256 txId = transactions.length;
        transactions.push(Transaction({destination: destination, executed: false, confirmationCount: 0, value: value}));
        emit Submission(txId);
    }

    function confirmTransaction(uint256 transactionId) public onlyOwner {
        if (transactionId >= transactions.length) revert TxDoesNotExist();
        if (confirmations[transactionId][msg.sender]) revert TxAlreadyConfirmed();

        confirmations[transactionId][msg.sender] = true;

        Transaction storage txn = transactions[transactionId];
        uint8 count;
        unchecked {
            count = txn.confirmationCount + 1;
        }
        txn.confirmationCount = count;

        emit Confirmation(msg.sender, transactionId);

        if (count >= required) {
            _executeTransaction(transactionId, txn);
        }
    }

    function executeTransaction(uint256 transactionId) public onlyOwner {
        if (transactionId >= transactions.length) revert TxDoesNotExist();
        Transaction storage txn = transactions[transactionId];
        if (txn.executed) revert TxAlreadyExecuted();

        if (txn.confirmationCount >= required) {
            _executeTransaction(transactionId, txn);
        }
    }

    function _executeTransaction(uint256 transactionId, Transaction storage txn) private {
        txn.executed = true;
        (bool success,) = txn.destination.call{value: txn.value}("");
        if (success) {
            emit Execution(transactionId);
        } else {
            txn.executed = false;
            emit ExecutionFailure(transactionId);
        }
    }

    function isOwner(address account) public view returns (bool) {
        return isOwnerMap[account];
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getConfirmations(uint256 transactionId) public view returns (address[] memory) {
        uint256 len = owners.length;
        address[] memory _confirmations = new address[](len);
        uint256 count;

        for (uint256 i; i < len;) {
            address owner = owners[i];
            if (confirmations[transactionId][owner]) {
                _confirmations[count] = owner;
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        }

        address[] memory result = new address[](count);
        for (uint256 i; i < count;) {
            result[i] = _confirmations[i];
            unchecked {
                ++i;
            }
        }
        return result;
    }
}

contract MultiSigWallet {
    address[] public owners;
    uint256 public required;

    struct Transaction {
        uint256 transactionID;
        address destination;
        uint256 value;
        uint256 confirmationCount;
        uint256 executionTimestamp;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    event Deposit(address indexed sender, uint256 value);
    event Submission(uint256 indexed transactionId);
    event Confirmation(address indexed owner, uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);

    modifier onlyOwner() {
        require(isOwner(msg.sender), "Not owner");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactionId < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notConfirmed(uint256 transactionId) {
        require(!confirmations[transactionId][msg.sender], "Transaction already confirmed");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed, "Transaction already executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid number of required confirmations");

        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            owners.push(_owners[i]);
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address destination, uint256 value) public onlyOwner {
        transactions.push(
            Transaction({
                transactionID: transactions.length,
                destination: destination,
                value: value,
                confirmationCount: 0,
                executionTimestamp: 0,
                executed: false
            })
        );

        emit Submission(transactions.length);
    }

    function confirmTransaction(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        transactions[transactionId].confirmationCount += 1;

        emit Confirmation(msg.sender, transactionId);

        if (transactions[transactionId].confirmationCount >= required) {
            executeTransaction(transactionId);
        }
    }

    function executeTransaction(uint256 transactionId)
        public
        onlyOwner
        transactionExists(transactionId)
        notExecuted(transactionId)
    {
        if (transactions[transactionId].confirmationCount >= required) {
            transactions[transactionId].executed = true;

            (bool success,) = transactions[transactionId].destination.call{value: transactions[transactionId].value}("");
            if (success) {
                emit Execution(transactionId);
            } else {
                transactions[transactionId].executed = false;
                emit ExecutionFailure(transactionId);
            }
        }
    }

    function isOwner(address account) public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == account) {
                return true;
            }
        }
        return false;
    }

    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    function getConfirmations(uint256 transactionId) public view returns (address[] memory) {
        address[] memory _confirmations = new address[](owners.length);
        uint256 count = 0;

        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                _confirmations[count] = owners[i];
                count += 1;
            }
        }

        address[] memory confirmationsTrimmed = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            confirmationsTrimmed[i] = _confirmations[i];
        }

        return confirmationsTrimmed;
    }
}
