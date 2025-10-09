// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ErrorsLib {
    error InvalidSignature();
    error SenderIsNotTheExecutor();
    error UpdateBalanceFailed();
    error InvalidAsyncNonce();
    error NotAnStaker();
    error InsufficientBalance();
    error InvalidAmount(uint256, uint256);
    error NotAnCA();
    error SenderIsNotTreasury();
    error WindowToChangeEvvmIDExpired();
}
