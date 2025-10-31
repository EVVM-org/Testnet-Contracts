// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title SignatureRecover
 * @author Mate labs
 * @notice Library for ECDSA signature verification and signer recovery in the EVVM ecosystem
 * @dev Provides utilities for verifying signatures against expected signers and recovering addresses from signatures.
 *      Uses ERC-191 standard message signing format with proper message hashing and signature validation.
 *
 * Key Features:
 * - EVVM-specific signature verification with structured message format
 * - ERC-191 compliant signature format (\x19Ethereum Signed Message)
 * - Safe signature splitting and validation
 * - Address recovery from message signatures
 *
 * Security Features:
 * - Validates signature length (must be 65 bytes)
 * - Ensures proper v value (27 or 28)
 * - Uses keccak256 hashing with ERC-191 message prefix
 * - Prevents signature malleability attacks
 *
 * Usage Pattern:
 * ```solidity
 * bool isValid = SignatureRecover.signatureVerification(
 *     evvmID,
 *     "functionName",
 *     string.concat(param1, ",", param2, ",", param3),
 *     signature,
 *     expectedAddress
 * );
 * ```
 */

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library SignatureRecover {
    /**
     * @notice Verifies that a signature matches the expected signer for EVVM operations
     * @dev Constructs a standardized message format and verifies the signature against the expected signer
     *
     * Message Format: "{evvmID},{functionName},{inputs}"
     * This creates a unique signature for each EVVM operation preventing replay attacks across:
     * - Different EVVM instances (via evvmID)
     * - Different functions (via functionName)
     * - Different parameters (via inputs)
     *
     * @param evvmID Unique identifier for the EVVM instance (prevents cross-chain replay)
     * @param functionName Name of the function being called (prevents cross-function replay)
     * @param inputs Comma-separated string of function inputs. Must be constructed using 
     *               string.concat(param1, ",", param2, ",", param3) 
     *               where all parameters are converted to strings
     * @param signature The ECDSA signature to verify (65 bytes: r(32) + s(32) + v(1))
     * @param expectedSigner Address that should have signed the message
     * @return bool True if the signature is valid and matches the expected signer, false otherwise
     */
    function signatureVerification(
        string memory evvmID,
        string memory functionName,
        string memory inputs,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        return
            recoverSigner(
                string.concat(evvmID, ",", functionName, ",", inputs),
                signature
            ) == expectedSigner;
    }

    /**
     * @notice Recovers the signer address from a message and its signature
     * @dev Uses ERC-191 standard message signing format with proper prefix and length encoding
     *
     * The message is hashed using the ERC-191 standard format:
     * keccak256("\x19Ethereum Signed Message:\n" + messageLength + message)
     *
     * This ensures compatibility with standard Ethereum wallets and signing tools like:
     * - MetaMask personal_sign
     * - web3.eth.personal.sign
     * - ethers.js signMessage
     *
     * @param message The original message that was signed (plain text)
     * @param signature The ECDSA signature (65 bytes: r + s + v)
     * @return address The recovered signer address, or zero address if signature is invalid
     */
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

    /**
     * @notice Splits a signature into its component parts (r, s, v)
     * @dev Extracts r, s, and v values from a 65-byte signature and validates the format
     *
     * Signature Format (65 bytes total):
     * - r: bytes 0-31 (32 bytes) - First part of ECDSA signature
     * - s: bytes 32-63 (32 bytes) - Second part of ECDSA signature
     * - v: byte 64 (1 byte) - Recovery identifier (27 or 28)
     *
     * Security validations:
     * - Ensures signature is exactly 65 bytes
     * - Normalizes v value to 27/28 if needed
     * - Validates v is either 27 or 28 (standard Ethereum values)
     *
     * @param signature The complete signature bytes to split (must be 65 bytes)
     * @return r The r component of the signature (bytes32)
     * @return s The s component of the signature (bytes32)
     * @return v The recovery identifier (uint8, either 27 or 28)
     */
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
