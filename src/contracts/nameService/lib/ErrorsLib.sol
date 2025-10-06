// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ErrorsLib {
    error SenderIsNotAdmin();
    error UserIsNotOwnerOfIdentity();
    error NonceAlreadyUsed();
    error InvalidSignatureOnNameService();
    /**
     * @dev Error thrown when a username is not valid.
     *      0x01 - Username is too short.
     *      0x02 - Username does not start with a letter.
     *      0x03 - Username contains invalid characters.
     */
    error InvalidUsername(bytes1);
    error UsernameAlreadyRegistered();
    error PreRegistrationNotValid();
    error MakeOfferVerificationFailed();
    error UserIsNotOwnerOfOffer();
    error AcceptOfferVerificationFailed();
    error RenewUsernameVerificationFailed();
    error EmptyCustomMetadata();
    error InvalidKey();
    error FlushUsernameVerificationFailed();
}
