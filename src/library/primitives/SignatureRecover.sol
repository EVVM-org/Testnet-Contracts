// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

library SignatureRecover {

    function recoverSigner(
        string memory message,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                AdvancedStrings.uintToString(bytes(message).length),
                message
            )
        );
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(messageHash, v, r, s);
    }

    function splitSignature(
        bytes memory signature
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        // Ensure signature is valid
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28, "Invalid signature value");
    }
}
