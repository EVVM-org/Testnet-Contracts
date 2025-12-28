// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

abstract contract NameServiceStructs {
    /**
     * @dev Struct for managing address change proposals with time delay
     * @param current Currently active address
     * @param proposal Proposed new address waiting for approval
     * @param timeToAccept Timestamp when the proposal can be accepted
     */
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    /**
     * @dev Struct for managing uint256 value proposals with time delay
     * @param current Currently active value
     * @param proposal Proposed new value waiting for approval
     * @param timeToAccept Timestamp when the proposal can be accepted
     */
    struct UintTypeProposal {
        uint256 current;
        uint256 proposal;
        uint256 timeToAccept;
    }

    /**
     * @dev Struct for managing boolean flag changes with time delay
     * @param flag Current boolean state
     * @param timeToAcceptChange Timestamp when the flag change can be executed
     */
    struct BoolTypeProposal {
        bool flag;
        uint256 timeToAcceptChange;
    }

    /**
     * @dev Core metadata for each registered identity/username
     * @param owner Address that owns this identity
     * @param expireDate Timestamp when the registration expires
     * @param customMetadataMaxSlots Number of custom metadata entries stored
     * @param offerMaxSlots Maximum number of offers that have been made
     * @param flagNotAUsername Flag indicating if this is a pre-registration (0x01) or actual username (0x00)
     */
    struct IdentityBaseMetadata {
        address owner;
        uint256 expireDate;
        uint256 customMetadataMaxSlots;
        uint256 offerMaxSlots;
        bytes1 flagNotAUsername;
    }


    /**
     * @dev Metadata for marketplace offers on usernames
     * @param offerer Address making the offer
     * @param expireDate Timestamp when the offer expires
     * @param amount Amount offered in Principal Tokens (after 0.5% marketplace fee deduction)
     */
    struct OfferMetadata {
        address offerer;
        uint256 expireDate;
        uint256 amount;
    }
}
