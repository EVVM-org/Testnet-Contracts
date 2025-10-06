// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ErrorsLib {
    error InsufficientBalance();
    error PrincipalTokenIsNotWithdrawable();
    error InvalidDepositAmount();
    error DepositAmountMustBeGreaterThanZero();
    error MailboxNotAuthorized();
    error SenderNotAuthorized();
    error ChainIdNotAuthorized();
    error InvalidSignature();
}
