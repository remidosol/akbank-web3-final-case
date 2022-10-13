// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBank {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function deposit(address _account) external payable;

    function withdraw(address _withdrawer, uint256 _amount) external payable;

    function transfer(address _from, address _to) external payable;

    function payPhoneBill() external payable returns (bool);

    function payInternetBill() external payable returns (bool);

    function payCreditDebt() external payable returns (bool);

    function payElectricityBill() external payable returns (bool);
}
