// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";

abstract contract MakeServicePaymentOnEvvm {
    IEvvm public evvm;

    constructor(address evvmAddress) {
        evvm = IEvvm(evvmAddress);
    }

    function makePay(
        address from,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        bytes memory signature
    ) internal virtual {
        evvm.pay(
            from,
            address(this),
            "",
            token,
            amount,
            priorityFee,
            nonce,
            priorityFlag,
            address(this),
            signature
        );
    }

    function makeCaPay(
        address to,
        address token,
        uint256 amount
    ) internal virtual {
        evvm.caPay(to, token, amount);
    }

    function _changeEvvmAddress(address newEvvmAddress) internal {
        evvm = IEvvm(newEvvmAddress);
    }
}
