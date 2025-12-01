// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

abstract contract SyncNonceService {
    mapping(address user => uint256 nonce) private syncServiceNonce;

    function _incrementSyncServiceNonce(address user) internal virtual {
        syncServiceNonce[user]++;
    }

    function getNextSyncServiceNonce(
        address user
    ) public view virtual returns (uint256) {
        return syncServiceNonce[user];
    }
}
