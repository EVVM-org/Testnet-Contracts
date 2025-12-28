// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

abstract contract AsyncNonce {
    error AsyncNonceAlreadyUsed();

    mapping(address user => mapping(uint256 nonce => bool availability))
        private asyncNonce;

    function markAsyncNonceAsUsed(
        address user,
        uint256 nonce
    ) internal virtual {
        asyncNonce[user][nonce] = true;
    }

    function verifyAsyncNonce(
        address user,
        uint256 nonce
    ) internal view virtual {
        if (asyncNonce[user][nonce]) revert AsyncNonceAlreadyUsed();
    }

    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) public view virtual returns (bool) {
        return asyncNonce[user][nonce];
    }
}
