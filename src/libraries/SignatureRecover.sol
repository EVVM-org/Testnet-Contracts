// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library SignatureRecover {
    function signatureVerification(
        string memory message,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        return recoverSigner(message, signature) == expectedSigner;
    }
    
    function recoverSigner(
        string memory message,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(bytes(message).length),
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
