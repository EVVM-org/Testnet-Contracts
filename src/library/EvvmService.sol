// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {EvvmStructs} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {SignatureUtil} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {AsyncNonce} from "@evvm/testnet-contracts/library/utils/nonces/AsyncNonce.sol";
import {StakingServiceUtils} from "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import {EvvmPayments} from "@evvm/testnet-contracts/library/utils/service/EvvmPayments.sol";

abstract contract EvvmService is
    AsyncNonce,
    StakingServiceUtils,
    EvvmPayments
{
    error InvalidServiceSignature();

    constructor(
        address evvmAddress,
        address stakingAddress
    ) StakingServiceUtils(stakingAddress) EvvmPayments(evvmAddress) {}

    function validateServiceSignature(
        string memory functionName,
        string memory inputs,
        bytes memory signature,
        address expectedSigner
    ) internal view virtual {
        if (
            !SignatureUtil.verifySignature(
                evvm.getEvvmID(),
                functionName,
                inputs,
                signature,
                expectedSigner
            )
        ) revert InvalidServiceSignature();
    }

    function getEvvmID() internal view returns (uint256) {
        return evvm.getEvvmID();
    }
}
