// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {IEvvm, EvvmStructs} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";

abstract contract EvvmPayments {
    IEvvm internal evvm;

    constructor(address evvmAddress) {}

    function requestPay(
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

    function requestDispersePay(
        EvvmStructs.DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        bytes memory signature
    ) internal virtual {
        evvm.dispersePay(
            address(this),
            toData,
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

    function makeDisperseCaPay(
        EvvmStructs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) internal virtual {
        evvm.disperseCaPay(toData, token, amount);
    }

    function _changeEvvmAddress(address newEvvmAddress) internal virtual {
        evvm = IEvvm(newEvvmAddress);
    }
}
