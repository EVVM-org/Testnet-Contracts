// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ITreasury {
    error DepositAmountMustBeGreaterThanZero();
    error InsufficientBalance();
    error InvalidDepositAmount();
    error PrincipalTokenIsNotWithdrawable();

    function deposit(address token, uint256 amount) external payable;

    function evvmAddress() external view returns (address);

    function withdraw(address token, uint256 amount) external;
}
