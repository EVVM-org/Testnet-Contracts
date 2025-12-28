// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title EvvmStructs
 * @dev Library of common structures used across EVVM and its services.
 *      This contract serves as a shared type system for the entire ecosystem,
 *      ensuring consistency in data structures between the core EVVM and
 *      external service contracts.
 *
 * @notice This contract should be inherited by both EVVM and service contracts
 *         that need to interact with these data structures.
 */

abstract contract EvvmStructs {
    struct PayData {
        address from;
        address to_address;
        string to_identity;
        address token;
        uint256 amount;
        uint256 priorityFee;
        uint256 nonce;
        bool priorityFlag;
        address executor;
        bytes signature;
    }

    struct DispersePayData {
        address from;
        DispersePayMetadata[] toData;
        address token;
        uint256 totalAmount;
        uint256 priorityFee;
        uint256 nonce;
        bool priorityFlag;
        address executor;
        bytes signature;
    }

    struct CaPayData {
        address from;
        address to;
        address token;
        uint256 amount;
    }

    struct DisperseCaPayData{
        address from;
        DisperseCaPayMetadata[] toData;
        address token;
        uint256 amount;
    }

    struct DispersePayMetadata {
        uint256 amount;
        address to_address;
        string to_identity;
    }

    struct DisperseCaPayMetadata {
        uint256 amount;
        address toAddress;
    }

    struct EvvmMetadata {
        string EvvmName;
        uint256 EvvmID;
        string principalTokenName;
        string principalTokenSymbol;
        address principalTokenAddress;
        uint256 totalSupply;
        uint256 eraTokens;
        uint256 reward;
    }

    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    struct UintTypeProposal {
        uint256 current;
        uint256 proposal;
        uint256 timeToAccept;
    }
}
