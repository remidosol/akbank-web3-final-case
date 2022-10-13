// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

import "./Bank.sol";

contract ElectricityCompany is Ownable {
    using Counters for Counters.Counter;

    // to store count of bill payments
    Counters.Counter public paymentCount;

    // declaration of the Bank instance.
    Bank bank;

    // the event which will be emitted when payment process has been completed
    event Paid(
        uint256 id,
        address indexed payer,
        uint256 billAmount,
        uint256 timestamps
    );

    // to save bill payments to a mapping, address as key and PaymentRecord as value
    mapping(address => PaymentRecord) public paymentRecords;

    // payment structure that will be recorded when payment completed
    struct PaymentRecord {
        uint256 id;
        address payer;
        uint256 billAmount;
        uint256 timestamps;
    }

    constructor(address payable _bankAddress) Ownable() {
        // initialization of Bank instance
        bank = Bank(_bankAddress);
    }

    // to pay electricity bill using bank instance
    function payElectricityBill(address _payer) external payable {
        bank.transfer{value: msg.value}(_payer, owner());

        paymentRecords[_payer] = PaymentRecord(
            paymentCount.current(),
            _payer,
            msg.value,
            block.timestamp
        );

        emit Paid(paymentCount.current(), _payer, msg.value, block.timestamp);

        paymentCount.increment();
    }
}
