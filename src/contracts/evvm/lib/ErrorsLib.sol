// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ErrorsLib {
    error SenderIsNotAdmin();
    error ImplementationIsNotActive();
    error InvalidSignature();
    error SenderIsNotTheExecutor();
    error SyncNonceMismatch();
    error AsyncNonceAlreadyUsed();
    error InsufficientBalance();
    error InvalidAmount();
    error NotAnCA();
    error SenderIsNotTreasury();

    error BreakerExploded();
    error WindowExpired();
    error AddressCantBeZero();
    error IncorrectAddressInput();
    error TimeLockNotExpired();
    error SenderIsNotTheProposedAdmin();
}
