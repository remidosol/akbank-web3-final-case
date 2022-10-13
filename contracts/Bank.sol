// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

import "./IBank.sol";
import "./PhoneOperator.sol";
import "./InternetProvider.sol";
import "./ElectricityCompany.sol";

contract Bank is Ownable, IBank {
    using Counters for Counters.Counter;

    // to store user balances
    mapping(address => uint256) private _balances;

    // to store total balance that is sum of all users' balances
    uint256 private _totalSupply;

    // initial dummy variables that are for interacting other contracts
    uint256 private constant phoneBill = 0.003 ether;
    uint256 private constant internetDebt = 0.005 ether;
    uint256 private constant creditDebt = 0.05 ether;
    uint256 private constant electricityDebt = 0.01 ether;

    // specifying debt types to differentiate debt payments
    enum DebtType {
        PHONE, // 0
        INTERNET, // 1
        ELECTRICITY, // 2
        CREDIT // 3
    }

    // skeleton of debt payments
    struct DebtPayment {
        address payer;
        uint256 amount;
        DebtType typeOfDebt;
        uint256 lastPayment;
    }

    // to store debt payments of users (some kind of receipts)
    mapping(address => DebtPayment[]) private payments;

    constructor() Ownable() {}

    // to deposit ether to the bank
    function deposit(address _account) external payable override(IBank) {
        require(
            msg.value >= 1 ether,
            "You should send equal or more than 1 ETH"
        );
        require(_account != address(0), "Deposit to the zero address");

        _totalSupply += msg.value;
        unchecked {
            _balances[_account] += msg.value;
        }

        emit Transfer(address(0), _account, msg.value);
        //_deposit(_account, msg.value);
    }

    // to withdraw ether from the bank
    function withdraw(address _withdrawer, uint256 _amount)
        external
        payable
        override(IBank)
    {
        _withdraw(_withdrawer, _amount);
    }

    // to transfer ether from msg.sender to another address
    function transfer(address _from, address _to)
        public
        payable
        override(IBank)
        balanceCheck(_from, msg.value)
    {
        require(_from != address(0), "Transfer to the zero address");
        require(_to != address(0), "Transfer to the zero address");

        uint256 fromBalance = _balances[_from];
        unchecked {
            _balances[_from] = fromBalance - msg.value;
            _balances[_to] += msg.value;
        }

        emit Transfer(_from, _to, msg.value);
    }

    // to get balance of an account
    function balanceOf(address _account) external view returns (uint256) {
        return _balances[_account];
    }

    // to get payments of an account
    function getPayments(address _account)
        external
        view
        returns (DebtPayment[] memory)
    {
        return payments[_account];
    }

    // to deposit ether to the bank (internal)
    // function _deposit(address _account, uint256 _amount) internal {
    //     require(_amount >= 1 ether, "You should send equal or more than 1 ETH");
    //     require(_account != address(0), "Deposit to the zero address");

    //     _totalSupply += _amount;
    //     unchecked {
    //         _balances[_account] += _amount;
    //     }

    //     emit Transfer(address(0), _account, _amount);
    // }

    // to transfer ether from msg.sender to another address
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) public payable balanceCheck(_from, _amount) {
        require(_from != address(0), "Transfer to the zero address");
        require(_to != address(0), "Transfer to the zero address");

        uint256 fromBalance = _balances[_from];
        unchecked {
            _balances[_from] = fromBalance - _amount;
            _balances[_to] += _amount;
        }

        emit Transfer(_from, _to, _amount);
    }

    // to withdraw ether from the bank (internal)
    function _withdraw(address _withdrawer, uint256 _amount)
        internal
        balanceCheck(_withdrawer, _amount)
    {
        require(_withdrawer != address(0), "Transfer to the zero address");

        uint256 toBalance = _balances[_withdrawer];
        unchecked {
            _balances[_withdrawer] = toBalance - _amount;
        }

        payable(_withdrawer).transfer(_amount);

        emit Transfer(owner(), _withdrawer, _amount);
    }

    // to pay phone bill using Bank
    function payPhoneBill(address _phoneOperatorAddress)
        external
        payable
        override(IBank)
        returns (bool)
    {
        return _payPhoneBill(msg.sender, msg.value, _phoneOperatorAddress);
    }

    // to pay internet bill using Bank
    function payInternetBill(address _internetProviderAddress)
        external
        payable
        override(IBank)
        returns (bool)
    {
        return
            _payInternetBill(msg.sender, msg.value, _internetProviderAddress);
    }

    // to pay electricity bill using Bank
    function payElectricityBill(address _electricityCompanyAddress)
        external
        payable
        override(IBank)
        returns (bool)
    {
        return
            _payElectricityBill(
                msg.sender,
                msg.value,
                _electricityCompanyAddress
            );
    }

    // to pay credit debt using Bank
    function payCreditDebt() external payable override(IBank) returns (bool) {
        return _payCreditDebt(msg.sender, msg.value);
    }

    // to pay phone bill using Bank (internal)
    function _payPhoneBill(
        address _payer,
        uint256 _amount,
        address _phoneOperatorAddress
    )
        internal
        balanceCheck(_payer, phoneBill)
        checkIsPaid(_payer)
        returns (bool)
    {
        PhoneOperator(_phoneOperatorAddress).payPhoneBill{value: _amount}(
            _payer
        );
        payments[_payer].push(
            DebtPayment(_payer, _amount, DebtType.PHONE, block.timestamp)
        );
        return true;
    }

    // to pay internet bill using Bank (internal)
    function _payInternetBill(
        address _payer,
        uint256 _amount,
        address _internetProviderAddress
    )
        internal
        balanceCheck(_payer, creditDebt)
        checkIsPaid(_payer)
        returns (bool)
    {
        InternetProvider(_internetProviderAddress).payInternetBill{
            value: _amount
        }(_payer);
        payments[_payer].push(
            DebtPayment(_payer, _amount, DebtType.INTERNET, block.timestamp)
        );
        return true;
    }

    // to pay electricity bill using Bank (internal)
    function _payElectricityBill(
        address _payer,
        uint256 _amount,
        address _electricityCompanyAddress
    )
        internal
        balanceCheck(_payer, electricityDebt)
        checkIsPaid(_payer)
        returns (bool)
    {
        ElectricityCompany(_electricityCompanyAddress).payElectricityBill{
            value: _amount
        }(_payer);
        payments[_payer].push(
            DebtPayment(_payer, _amount, DebtType.ELECTRICITY, block.timestamp)
        );
        return true;
    }

    // to pay credit debt using Bank (internal)
    function _payCreditDebt(address _payer, uint256 _amount)
        internal
        balanceCheck(_payer, creditDebt)
        checkIsPaid(_payer)
        returns (bool)
    {
        _transfer(_payer, owner(), _amount);
        payments[_payer].push(
            DebtPayment(_payer, _amount, DebtType.CREDIT, block.timestamp)
        );
        return true;
    }

    // to check user balance according to given amount
    modifier balanceCheck(address _userAddress, uint256 _amount) {
        require(
            _balances[_userAddress] >= _amount,
            "Your balance is insufficient"
        );
        _;
    }

    // to check that user whether paid his/her debts or not in 4 weeks (1 month)
    modifier checkIsPaid(address _payer) {
        if (payments[_payer].length == 0) {
            _;
        } else {
            uint256 lastPayment = payments[_payer][payments[_payer].length - 1]
                .lastPayment;
            require(
                lastPayment >= lastPayment + 4 weeks,
                "You already paid this bill!"
            );
            _;
        }
    }

    // to check msg.value is greater than zero (0)
    modifier isMsgValueValid(uint256 msgValue) {
        require(msgValue > 0, "You should send valid amount");
        _;
    }

    // low level interactions without receiving data
    receive() external payable isMsgValueValid(msg.value) {
        _totalSupply += msg.value;
        unchecked {
            _balances[msg.sender] += msg.value;
        }

        emit Transfer(address(0), owner(), msg.value);
    }

    // low level interactions with receiving data or without receiving data
    fallback() external payable isMsgValueValid(msg.value) {
        _totalSupply += msg.value;
        unchecked {
            _balances[owner()] += msg.value;
        }

        emit Transfer(address(0), owner(), msg.value);
    }
}
