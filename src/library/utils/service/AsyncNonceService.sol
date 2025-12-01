// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

abstract contract AsyncNonceService {

    error ServiceAsyncNonceAlreadyUsed();

    mapping(address user => mapping(uint256 nonce => bool availability))
        private asyncServiceNonce;

    function markAsyncServiceNonceAsUsed(
        address user,
        uint256 nonce
    ) internal virtual {
        asyncServiceNonce[user][nonce] = true;
    }

    function verifyAsyncServiceNonce(
        address user,
        uint256 nonce
    ) internal view virtual {
        if (asyncServiceNonce[user][nonce])
            revert ServiceAsyncNonceAlreadyUsed();
    }

    function isAsyncServiceNonceAvailable(
        address user,
        uint256 nonce
    ) public view virtual returns (bool) {
        return asyncServiceNonce[user][nonce];
    }
}
