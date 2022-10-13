// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

import "./Bank.sol";

contract WorkerPayroll is Ownable {
    using Counters for Counters.Counter;

    // declaration of the Bank instance.
    Bank bank;

    // declaration company balance that held in Bank.
    uint256 public companyBalance;

    // the total salary that will be paid all workers
    uint256 public totalSalary = 0;

    // the total worker count
    Counters.Counter public totalWorkers;

    // the total of payment count that are happened
    Counters.Counter public totalPayment;

    constructor(address payable _bankAddress) Ownable() {
        // initialization of Bank instance
        bank = Bank(_bankAddress);

        // initialization of companyBalance that held in the bank
        companyBalance = bank.balanceOf(owner());
    }

    // the event which will be emitted when payment process has been completed
    event Paid(
        uint256 id,
        address from,
        uint256 totalSalary,
        uint256 timestamp
    );

    // to check the address belongs to whether a worker or not
    mapping(address => bool) private isWorker;

    // payment and worker structure that will be recorded when payment completed
    struct WorkerPayment {
        uint256 id;
        address worker;
        uint256 salary;
        uint256 lastPayment;
    }

    // to save worker payments to an array as structured WorkerPayment
    WorkerPayment[] private employees;

    // to add workers
    function addWorker(address worker, uint256 salary)
        external
        onlyOwner
        returns (bool)
    {
        require(salary > 0 ether, "Salary cannot be zero!");
        require(!isWorker[worker], "Record already existing!");

        totalWorkers.increment();
        totalSalary += salary;
        isWorker[worker] = true;

        employees.push(
            WorkerPayment(
                totalWorkers.current(),
                worker,
                salary,
                block.timestamp
            )
        );

        return true;
    }

    // to pay workers using Bank instance
    function payWorkers() external payable onlyOwner returns (bool) {
        //require(msg.value >= totalSalary, "Ethers too small");
        require(totalSalary <= companyBalance, "Insufficient balance");

        for (uint256 i = 0; i < employees.length; i++) {
            bank.transfer{value: employees[i].salary}(
                owner(),
                employees[i].worker
            );
            employees[i].lastPayment = block.timestamp;
            companyBalance -= employees[i].salary;
        }

        totalPayment.increment();

        emit Paid(
            totalPayment.current(),
            owner(),
            totalSalary,
            block.timestamp
        );

        return true;
    }

    // to fund company using Bank instance
    function fundCompany() external payable returns (bool) {
        require(owner() != msg.sender, "You can't fund yourself!");
        bank.deposit{value: msg.value}(owner());
        companyBalance += msg.value;
        return true;
    }

    // to get all employees (workers)
    function getWorkers() external view returns (WorkerPayment[] memory) {
        return employees;
    }
}
