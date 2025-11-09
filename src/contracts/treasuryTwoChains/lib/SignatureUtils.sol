// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

import {SignatureRecover} from "@evvm/testnet-contracts/library/SignatureRecover.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/AdvancedStrings.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.0;

/**
 * @title SignatureUtils
 * @author Mate labs
 * @notice Signature verification utilities for Treasury Cross-Chain Fisher Bridge operations
 * @dev Specialized signature verification for Fisher Bridge transactions in the EVVM cross-chain treasury system
 *      Provides EIP-191 compliant signature verification with structured message format for enhanced security
 * 
 * Key Features:
 * - EIP-191 standard message signing format for wallet compatibility
 * - Fisher Bridge specific message structure for transaction authenticity
 * - Nonce-based replay attack prevention
 * - EVVM ID integration for cross-instance security
 * - Support for both ETH and ERC20 token bridge operations
 * 
 * Security Model:
 * - Structured message format: "{evvmID},fisherBridge,{parameters}"
 * - Nonce validation prevents replay attacks across chains
 * - EVVM ID ensures signatures are valid only for specific EVVM instances
 * - Address and amount validation through signature verification
 */
library SignatureUtils {
    /// @notice Verifies Fisher Bridge transaction signatures using EIP-191 standard
    /// @dev Constructs and verifies structured message for Fisher Bridge cross-chain operations
    ///      Message format: "{evvmID},fisherBridge,{addressToReceive},{nonce},{tokenAddress},{priorityFee},{amount}"
    ///      This ensures each signature is unique and prevents cross-chain replay attacks
    /// 
    /// @param evvmID Unique identifier of the EVVM instance (prevents cross-instance replay)
    /// @param signer Address that should have signed the message (transaction originator)
    /// @param addressToReceive Destination address on the target chain for the bridged tokens
    /// @param nonce Sequential nonce for the user to prevent replay attacks
    /// @param tokenAddress Contract address of the token being bridged (address(0) for ETH)
    /// @param priorityFee Fee amount paid to Fisher executor for priority processing
    /// @param amount Total amount of tokens being bridged across chains
    /// @param signature ECDSA signature (65 bytes) created by the signer using their private key
    /// @return bool True if the signature is valid and matches the expected signer, false otherwise
    /// 
    /// @dev Security Features:
    ///      - EIP-191 compliance ensures wallet compatibility (MetaMask, WalletConnect, etc.)
    ///      - Structured message prevents parameter manipulation
    ///      - EVVM ID binding prevents cross-instance attacks
    ///      - Nonce inclusion prevents replay attacks
    ///      - All parameters are included in signature for integrity verification
    function verifyMessageSignedForFisherBridge(
        uint256 evvmID,
        address signer,
        address addressToReceive,
        uint256 nonce,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                Strings.toString(evvmID),
                "fisherBridge",
                string.concat(
                    AdvancedStrings.addressToString(addressToReceive),
                    ",",
                    Strings.toString(nonce),
                    ",",
                    AdvancedStrings.addressToString(tokenAddress),
                    ",",
                    Strings.toString(priorityFee),
                    ",",
                    Strings.toString(amount)
                ),
                signature,
                signer
            );
    }
}
