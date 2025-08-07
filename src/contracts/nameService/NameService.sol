// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;
/**
 _   _                            
| \ | |                           
|  \| | __ _ _ __ ___   ___       
| . ` |/ _` | '_ ` _ \ / _ \      
| |\  | (_| | | | | | |  __/      
\_| \_/\__,_|_| |_| |_|\___|      
                                  
                                  
 _____                 _          
/  ___|               (_)         
\ `--.  ___ _ ____   ___  ___ ___ 
 `--. \/ _ | '__\ \ / | |/ __/ _ \
/\__/ |  __| |   \ V /| | (_|  __/
\____/ \___|_|    \_/ |_|\___\___|
                                  

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
 *
 * @title EVVM Name Service Contract
 * @author jistro.eth ariutokintumi.eth
 * @notice This contract manages username registration and domain name services for the EVVM ecosystem
 * @dev Provides a comprehensive domain name system with features including:
 *
 * Core Features:
 * - Username registration with pre-registration protection against front-running
 * - Custom metadata management with schema-based data storage
 * - Username trading system with offers and marketplace functionality
 * - Renewal system with dynamic pricing based on market demand
 * - Time-delayed governance for administrative functions
 *
 * Registration Process:
 * 1. Pre-register: Commit to a username hash to prevent front-running
 * 2. Register: Reveal the username and complete registration within 30 minutes
 * 3. Manage: Add custom metadata, handle offers, and renew as needed
 *
 * Security Features:
 * - Signature verification for all operations
 * - Nonce-based replay protection
 * - Time-locked administrative changes
 * - Integration with EVVM core for secure payments
 *
 * Economic Model:
 * - Registration costs 100x EVVM reward amount
 * - Custom metadata operations cost 10x EVVM reward amount
 * - Renewal pricing varies based on market demand and timing
 * - Marketplace takes 0.5% fee on username sales
 */

import {Evvm} from "@EVVM/testnet/contracts/evvm/Evvm.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AdvancedStrings} from "@EVVM/testnet/lib/AdvancedStrings.sol";
import {ErrorsLib} from "@EVVM/testnet/contracts/nameService/lib/ErrorsLib.sol";
import {SignatureUtils} from "@EVVM/testnet/contracts/nameService/lib/SignatureUtils.sol";

contract NameService {
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

    /// @dev Mapping from username to its core metadata and registration details
    mapping(string username => IdentityBaseMetadata basicMetadata)
        private identityDetails;

    /**
     * @dev Metadata for marketplace offers on usernames
     * @param offerer Address making the offer
     * @param expireDate Timestamp when the offer expires
     * @param amount Amount offered in MATE tokens (after 0.5% marketplace fee deduction)
     */
    struct OfferMetadata {
        address offerer;
        uint256 expireDate;
        uint256 amount;
    }

    /// @dev Nested mapping: username => offer ID => offer details
    mapping(string username => mapping(uint256 id => OfferMetadata))
        private usernameOffers;

    /// @dev Nested mapping: username => metadata key => custom value string
    mapping(string username => mapping(uint256 numberKey => string customValue))
        private identityCustomMetadata;

    /// @dev Mapping to track used nonces per address to prevent replay attacks
    mapping(address => mapping(uint256 => bool)) private nameServiceNonce;

    /// @dev Proposal system for token withdrawal amounts with time delay
    UintTypeProposal amountToWithdrawTokens;

    /// @dev Proposal system for EVVM contract address changes with time delay
    AddressTypeProposal evvmAddress;

    /// @dev Proposal system for admin address changes with time delay
    AddressTypeProposal admin;

    /// @dev Constant address representing the MATE token in the EVVM ecosystem
    address private constant PRINCIPAL_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    /// @dev Amount of MATE tokens locked in pending marketplace offers
    uint256 private mateTokenLockedForWithdrawOffers;

    /// @dev Restricts function access to the current admin address only
    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert ErrorsLib.SenderIsNotAdmin();

        _;
    }

    /// @dev Verifies that the caller owns the specified identity/username
    modifier onlyOwnerOfIdentity(address _user, string memory _identity) {
        if (identityDetails[_identity].owner != _user)
            revert ErrorsLib.UserIsNotOwnerOfIdentity();

        _;
    }

    /// @dev Ensures the nonce hasn't been used before to prevent replay attacks
    modifier verifyIfNonceIsAvailable(address _user, uint256 _nonce) {
        if (nameServiceNonce[_user][_nonce])
            revert ErrorsLib.NonceAlreadyUsed();

        _;
    }

    /**
     * @notice Initializes the NameService contract
     * @dev Sets up the EVVM integration and initial admin
     * @param _evvmAddress Address of the EVVM core contract for payment processing
     * @param _initialOwner Address that will have admin privileges
     */
    constructor(address _evvmAddress, address _initialOwner) {
        evvmAddress.current = _evvmAddress;
        admin.current = _initialOwner;
    }

    /**
     * @notice Pre-registers a username hash to prevent front-running attacks
     * @dev Creates a temporary reservation that can be registered 30 minutes later
     * @param user Address of the user making the pre-registration
     * @param hashPreRegisteredUsername Keccak256 hash of username + random number
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function preRegistrationUsername(
        address user,
        bytes32 hashPreRegisteredUsername,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) public verifyIfNonceIsAvailable(user, nonce) {
        if (
            !SignatureUtils.verifyMessageSignedForPreRegistrationUsername(
                user,
                hashPreRegisteredUsername,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        if (priorityFee_EVVM > 0) {
            makePay(
                user,
                0,
                priorityFee_EVVM,
                nonce_EVVM,
                priorityFlag_EVVM,
                signature_EVVM
            );
        }

        string memory key = string.concat(
            "@",
            AdvancedStrings.bytes32ToString(hashPreRegisteredUsername)
        );

        identityDetails[key] = IdentityBaseMetadata({
            owner: user,
            expireDate: block.timestamp + 30 minutes,
            customMetadataMaxSlots: 0,
            offerMaxSlots: 0,
            flagNotAUsername: 0x01
        });

        nameServiceNonce[user][nonce] = true;

        if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                Evvm(evvmAddress.current).getRewardAmount() + priorityFee_EVVM
            );
        }
    }

    /**
     * @notice Completes username registration using a pre-registration commitment
     * @dev Must be called after the pre-registration period (30 minutes) has reached
     * @param user Address of the user completing the registration
     * @param username The actual username being registered (revealed from hash)
     * @param clowNumber Random number used in the pre-registration hash
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function registrationUsername(
        address user,
        string memory username,
        uint256 clowNumber,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) public verifyIfNonceIsAvailable(user, nonce) {
        if (admin.current != user) isValidUsername(username);

        if (!isUsernameAvailable(username)) {
            revert ErrorsLib.UsernameAlreadyRegistered();
        }

        if (
            !SignatureUtils.verifyMessageSignedForRegistrationUsername(
                user,
                username,
                clowNumber,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        makePay(
            user,
            getPricePerRegistration(),
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        string memory _key = string.concat(
            "@",
            AdvancedStrings.bytes32ToString(hashUsername(username, clowNumber))
        );

        if (
            identityDetails[_key].owner != user ||
            identityDetails[_key].expireDate > block.timestamp
        ) revert ErrorsLib.PreRegistrationNotValid();

        identityDetails[username] = IdentityBaseMetadata({
            owner: user,
            expireDate: block.timestamp + 366 days,
            customMetadataMaxSlots: 0,
            offerMaxSlots: 0,
            flagNotAUsername: 0x00
        });

        nameServiceNonce[user][nonce] = true;

        if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (50 * Evvm(evvmAddress.current).getRewardAmount()) +
                    priorityFee_EVVM
            );
        }

        delete identityDetails[_key];
    }

    /**
     * @notice Creates a marketplace offer to purchase a username
     * @dev Locks the offer amount in the contract until withdrawn or accepted
     * @param user Address making the offer
     * @param username Target username for the offer
     * @param expireDate Timestamp when the offer expires
     * @param amount Amount being offered in MATE tokens
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     * @return offerID Unique identifier for the created offer
     */
    function makeOffer(
        address user,
        string memory username,
        uint256 expireDate,
        uint256 amount,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) public verifyIfNonceIsAvailable(user, nonce) returns (uint256 offerID) {
        if (
            identityDetails[username].flagNotAUsername == 0x01 ||
            !verifyIfIdentityExists(username) ||
            amount == 0 ||
            expireDate <= block.timestamp
        ) revert ErrorsLib.PreRegistrationNotValid();

        if (
            !SignatureUtils.verifyMessageSignedForMakeOffer(
                user,
                username,
                expireDate,
                amount,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        makePay(
            user,
            amount,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        while (usernameOffers[username][offerID].offerer != address(0)) {
            offerID++;
        }

        usernameOffers[username][offerID] = OfferMetadata({
            offerer: user,
            expireDate: expireDate,
            amount: ((amount * 995) / 1000)
        });

        makeCaPay(
            msg.sender,
            Evvm(evvmAddress.current).getRewardAmount() +
                ((amount * 125) / 100_000) +
                priorityFee_EVVM
        );
        mateTokenLockedForWithdrawOffers +=
            ((amount * 995) / 1000) +
            (amount / 800);

        if (offerID > identityDetails[username].offerMaxSlots) {
            identityDetails[username].offerMaxSlots++;
        } else if (identityDetails[username].offerMaxSlots == 0) {
            identityDetails[username].offerMaxSlots++;
        }

        nameServiceNonce[user][nonce] = true;
    }

    /**
     * @notice Withdraws a marketplace offer and refunds the locked tokens
     * @dev Can only be called by the offer creator before expiration
     * @param user Address that made the original offer
     * @param username Username the offer was made for
     * @param offerID Unique identifier of the offer to withdraw
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function withdrawOffer(
        address user,
        string memory username,
        uint256 offerID,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) public verifyIfNonceIsAvailable(user, nonce) {
        if (usernameOffers[username][offerID].offerer != user)
            revert ErrorsLib.UserIsNotOwnerOfOffer();

        if (
            !SignatureUtils.verifyMessageSignedForWithdrawOffer(
                user,
                username,
                offerID,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        if (priorityFee_EVVM > 0) {
            makePay(
                user,
                0,
                priorityFee_EVVM,
                nonce_EVVM,
                priorityFlag_EVVM,
                signature_EVVM
            );
        }

        makeCaPay(user, usernameOffers[username][offerID].amount);

        usernameOffers[username][offerID].offerer = address(0);

        makeCaPay(
            msg.sender,
            Evvm(evvmAddress.current).getRewardAmount() +
                ((usernameOffers[username][offerID].amount * 1) / 796) +
                priorityFee_EVVM
        );

        mateTokenLockedForWithdrawOffers -=
            (usernameOffers[username][offerID].amount) +
            (((usernameOffers[username][offerID].amount * 1) / 199) / 4);

        nameServiceNonce[user][nonce] = true;
    }

    /**
     * @notice Accepts a marketplace offer and transfers username ownership
     * @dev Can only be called by the current username owner before offer expiration
     * @param user Address of the current username owner
     * @param username Username being sold
     * @param offerID Unique identifier of the offer to accept
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function acceptOffer(
        address user,
        string memory username,
        uint256 offerID,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    )
        public
        onlyOwnerOfIdentity(user, username)
        verifyIfNonceIsAvailable(user, nonce)
    {
        if (
            usernameOffers[username][offerID].offerer == address(0) ||
            usernameOffers[username][offerID].expireDate < block.timestamp
        ) revert ErrorsLib.AcceptOfferVerificationFailed();

        if (
            !SignatureUtils.verifyMessageSignedForAcceptOffer(
                user,
                username,
                offerID,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        if (priorityFee_EVVM > 0) {
            makePay(
                user,
                0,
                priorityFee_EVVM,
                nonce_EVVM,
                priorityFlag_EVVM,
                signature_EVVM
            );
        }

        makeCaPay(user, usernameOffers[username][offerID].amount);

        identityDetails[username].owner = usernameOffers[username][offerID]
            .offerer;

        usernameOffers[username][offerID].offerer = address(0);

        if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (Evvm(evvmAddress.current).getRewardAmount()) +
                    (((usernameOffers[username][offerID].amount * 1) / 199) /
                        4) +
                    priorityFee_EVVM
            );
        }

        mateTokenLockedForWithdrawOffers -=
            (usernameOffers[username][offerID].amount) +
            (((usernameOffers[username][offerID].amount * 1) / 199) / 4);

        nameServiceNonce[user][nonce] = true;
    }

    /**
     * @notice Renews a username registration for another year
     * @dev Pricing varies based on timing and market demand for the username
     *
     * Pricing Rules:
     * - Free renewal if done within 1 year of expiration (limited time offer)
     * - Variable cost based on highest active offer (minimum 500 MATE)
     * - Fixed 500,000 MATE if renewed more than 1 year before expiration
     * - Can be renewed up to 100 years in advance
     *
     * @param user Address of the username owner
     * @param username Username to renew
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function renewUsername(
        address user,
        string memory username,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    )
        public
        onlyOwnerOfIdentity(user, username)
        verifyIfNonceIsAvailable(user, nonce)
    {
        if (
            identityDetails[username].flagNotAUsername == 0x01 ||
            identityDetails[username].expireDate > block.timestamp + 36500 days
        ) revert ErrorsLib.RenewUsernameVerificationFailed();

        if (
            !SignatureUtils.verifyMessageSignedForRenewUsername(
                user,
                username,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        uint256 priceOfRenew = seePriceToRenew(username);

        makePay(
            user,
            priceOfRenew,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                Evvm(evvmAddress.current).getRewardAmount() +
                    ((priceOfRenew * 50) / 100) +
                    priorityFee_EVVM
            );
        }

        identityDetails[username].expireDate += 366 days;
        nameServiceNonce[user][nonce] = true;
    }

    /**
     * @notice Adds custom metadata to a username following a standardized schema format
     * @dev Metadata follows format: [schema]:[subschema]>[value]
     *
     * Standard Format Examples:
     * - memberOf:>EVVM
     * - socialMedia:x>jistro (Twitter/X handle)
     * - email:dev>jistro[at]evvm.org (development email)
     * - email:callme>contact[at]jistro.xyz (contact email)
     *
     * Schema Guidelines:
     * - Based on https://schema.org/docs/schemas.html
     * - ':' separates schema from subschema
     * - '>' separates metadata from value
     * - Pad with spaces if schema/subschema < 5 characters
     * - Use "socialMedia" for social networks with network name as subschema
     *
     * @param user Address of the username owner
     * @param identity Username to add metadata to
     * @param value Metadata string following the standardized format
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function addCustomMetadata(
        address user,
        string memory identity,
        string memory value,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    )
        public
        onlyOwnerOfIdentity(user, identity)
        verifyIfNonceIsAvailable(user, nonce)
    {
        if (bytes(value).length == 0) revert ErrorsLib.EmptyCustomMetadata();

        if (
            !SignatureUtils.verifyMessageSignedForAddCustomMetadata(
                user,
                identity,
                value,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        makePay(
            user,
            getPriceToAddCustomMetadata(),
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (5 * Evvm(evvmAddress.current).getRewardAmount()) +
                    ((getPriceToAddCustomMetadata() * 50) / 100) +
                    priorityFee_EVVM
            );
        }

        identityCustomMetadata[identity][
            identityDetails[identity].customMetadataMaxSlots
        ] = value;

        identityDetails[identity].customMetadataMaxSlots++;
        nameServiceNonce[user][nonce] = true;
    }

    /**
     * @notice Removes a specific custom metadata entry by key and reorders the array
     * @dev Shifts all subsequent metadata entries to fill the gap after removal
     * @param user Address of the username owner
     * @param identity Username to remove metadata from
     * @param key Index of the metadata entry to remove
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function removeCustomMetadata(
        address user,
        string memory identity,
        uint256 key,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    )
        public
        onlyOwnerOfIdentity(user, identity)
        verifyIfNonceIsAvailable(user, nonce)
    {
        if (
            !SignatureUtils.verifyMessageSignedForRemoveCustomMetadata(
                user,
                identity,
                key,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        if (identityDetails[identity].customMetadataMaxSlots <= key)
            revert ErrorsLib.InvalidKey();

        makePay(
            user,
            getPriceToRemoveCustomMetadata(),
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        if (identityDetails[identity].customMetadataMaxSlots == key) {
            delete identityCustomMetadata[identity][key];
        } else {
            for (
                uint256 i = key;
                i < identityDetails[identity].customMetadataMaxSlots;
                i++
            ) {
                identityCustomMetadata[identity][i] = identityCustomMetadata[
                    identity
                ][i + 1];
            }
            delete identityCustomMetadata[identity][
                identityDetails[identity].customMetadataMaxSlots
            ];
        }
        identityDetails[identity].customMetadataMaxSlots--;
        nameServiceNonce[user][nonce] = true;
        if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (5 * Evvm(evvmAddress.current).getRewardAmount()) +
                    priorityFee_EVVM
            );
        }
    }

    /**
     * @notice Removes all custom metadata entries for a username
     * @dev More gas-efficient than removing entries individually
     * @param user Address of the username owner
     * @param identity Username to flush all metadata from
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function flushCustomMetadata(
        address user,
        string memory identity,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    )
        public
        onlyOwnerOfIdentity(user, identity)
        verifyIfNonceIsAvailable(user, nonce)
    {
        if (
            !SignatureUtils.verifyMessageSignedForFlushCustomMetadata(
                user,
                identity,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        if (identityDetails[identity].customMetadataMaxSlots == 0)
            revert ErrorsLib.EmptyCustomMetadata();

        makePay(
            user,
            getPriceToFlushCustomMetadata(identity),
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        for (
            uint256 i = 0;
            i < identityDetails[identity].customMetadataMaxSlots;
            i++
        ) {
            delete identityCustomMetadata[identity][i];
        }

        if (Evvm(evvmAddress.current).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                ((5 * Evvm(evvmAddress.current).getRewardAmount()) *
                    identityDetails[identity].customMetadataMaxSlots) +
                    priorityFee_EVVM
            );
        }

        identityDetails[identity].customMetadataMaxSlots = 0;
        nameServiceNonce[user][nonce] = true;
    }

    /**
     * @notice Completely removes a username registration and all associated data
     * @dev Deletes the username, all custom metadata, and makes it available for re-registration
     * @param user Address of the username owner
     * @param username Username to completely remove from the system
     * @param nonce Unique nonce to prevent replay attacks
     * @param signature Signature proving authorization for this operation
     * @param priorityFee_EVVM Priority fee for faster transaction processing
     * @param nonce_EVVM Nonce for the EVVM payment transaction
     * @param priorityFlag_EVVM True for async payment, false for sync payment
     * @param signature_EVVM Signature for the EVVM payment transaction
     */
    function flushUsername(
        address user,
        string memory username,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    )
        public
        verifyIfNonceIsAvailable(user, nonce)
        onlyOwnerOfIdentity(user, username)
    {
        if (
            block.timestamp >= identityDetails[username].expireDate ||
            identityDetails[username].flagNotAUsername == 0x01
        ) revert ErrorsLib.FlushUsernameVerificationFailed();

        if (
            !SignatureUtils.verifyMessageSignedForFlushUsername(
                user,
                username,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnNameService();

        makePay(
            user,
            getPriceToFlushUsername(username),
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        for (
            uint256 i = 0;
            i < identityDetails[username].customMetadataMaxSlots;
            i++
        ) {
            delete identityCustomMetadata[username][i];
        }

        makeCaPay(
            msg.sender,
            ((5 * Evvm(evvmAddress.current).getRewardAmount()) *
                identityDetails[username].customMetadataMaxSlots) +
                priorityFee_EVVM
        );

        identityDetails[username] = IdentityBaseMetadata({
            owner: address(0),
            expireDate: 0,
            customMetadataMaxSlots: 0,
            offerMaxSlots: identityDetails[username].offerMaxSlots,
            flagNotAUsername: 0x00
        });
        nameServiceNonce[user][nonce] = true;
    }

    //█ Administrative Functions with Time-Delayed Governance ████████████████████████████████████

    /**
     * @notice Proposes a new admin address with 1-day time delay
     * @dev Part of the time-delayed governance system for admin changes
     * @param _adminToPropose Address of the proposed new admin
     */
    function proposeAdmin(address _adminToPropose) public onlyAdmin {
        if (_adminToPropose == address(0) || _adminToPropose == admin.current) {
            revert();
        }

        admin.proposal = _adminToPropose;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    /**
     * @notice Cancels the current admin proposal
     * @dev Only the current admin can cancel pending proposals
     */
    function cancelProposeAdmin() public onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice Accepts the admin proposal and becomes the new admin
     * @dev Can only be called by the proposed admin after the time delay has passed
     */
    function acceptProposeAdmin() public {
        if (admin.proposal != msg.sender) {
            revert();
        }
        if (block.timestamp < admin.timeToAccept) {
            revert();
        }

        admin = AddressTypeProposal({
            current: admin.proposal,
            proposal: address(0),
            timeToAccept: 0
        });
    }

    /**
     * @notice Proposes to withdraw MATE tokens from the contract
     * @dev Amount must be available after reserving funds for operations and locked offers
     * @param _amount Amount of MATE tokens to withdraw
     */
    function proposeWithdrawMateTokens(uint256 _amount) public onlyAdmin {
        if (
            Evvm(evvmAddress.current).getBalance(
                address(this),
                PRINCIPAL_TOKEN_ADDRESS
            ) -
                (5083 +
                    Evvm(evvmAddress.current).getRewardAmount() +
                    mateTokenLockedForWithdrawOffers) <
            _amount ||
            _amount == 0
        ) {
            revert();
        }

        amountToWithdrawTokens.proposal = _amount;
        amountToWithdrawTokens.timeToAccept = block.timestamp + 1 days;
    }

    /**
     * @notice Cancels the pending token withdrawal proposal
     * @dev Only the current admin can cancel pending proposals
     */
    function cancelWithdrawMateTokens() public onlyAdmin {
        amountToWithdrawTokens.proposal = 0;
        amountToWithdrawTokens.timeToAccept = 0;
    }

    /**
     * @notice Executes the approved token withdrawal
     * @dev Can only be called after the time delay has passed
     */
    function claimWithdrawMateTokens() public onlyAdmin {
        if (block.timestamp < amountToWithdrawTokens.timeToAccept) {
            revert();
        }

        makeCaPay(admin.current, amountToWithdrawTokens.proposal);

        amountToWithdrawTokens.proposal = 0;
        amountToWithdrawTokens.timeToAccept = 0;
    }

    /**
     * @notice Proposes to change the EVVM contract address
     * @dev Critical function that affects payment processing integration
     * @param _newEvvmAddress Address of the new EVVM contract
     */
    function proposeChangeEvvmAddress(
        address _newEvvmAddress
    ) public onlyAdmin {
        if (_newEvvmAddress == address(0)) {
            revert();
        }
        evvmAddress.proposal = _newEvvmAddress;
        evvmAddress.timeToAccept = block.timestamp + 1 days;
    }

    /**
     * @notice Cancels the pending EVVM address change proposal
     * @dev Only the current admin can cancel pending proposals
     */
    function cancelChangeEvvmAddress() public onlyAdmin {
        evvmAddress.proposal = address(0);
        evvmAddress.timeToAccept = 0;
    }

    /**
     * @notice Executes the approved EVVM address change
     * @dev Can only be called after the time delay has passed
     */
    function acceptChangeEvvmAddress() public onlyAdmin {
        if (block.timestamp < evvmAddress.timeToAccept) {
            revert();
        }
        evvmAddress = AddressTypeProposal({
            current: evvmAddress.proposal,
            proposal: address(0),
            timeToAccept: 0
        });
    }

    //█ Utility Functions ████████████████████████████████████████████████████████████████████████

    //█ EVVM Payment Integration ██████████████████████████████████████████████

    /**
     * @notice Internal function to handle payments through the EVVM contract
     * @dev Supports both synchronous and asynchronous payment modes
     * @param user Address making the payment
     * @param ammount Amount to pay in MATE tokens
     * @param priorityFee Additional priority fee for faster processing
     * @param nonce Nonce for the EVVM transaction
     * @param priorityFlag True for async payment, false for sync payment
     * @param signature Signature authorizing the payment
     */
    function makePay(
        address user,
        uint256 ammount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        bytes memory signature
    ) internal {
        if (priorityFlag) {
            Evvm(evvmAddress.current).payMateStaking_async(
                user,
                address(this),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                ammount,
                priorityFee,
                nonce,
                address(this),
                signature
            );
        } else {
            Evvm(evvmAddress.current).payMateStaking_sync(
                user,
                address(this),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                ammount,
                priorityFee,
                address(this),
                signature
            );
        }
    }

    /**
     * @notice Internal function to distribute MATE tokens to users
     * @dev Calls the EVVM contract's caPay function for token distribution
     * @param user Address to receive the tokens
     * @param amount Amount of MATE tokens to distribute
     */
    function makeCaPay(address user, uint256 amount) internal {
        Evvm(evvmAddress.current).caPay(user, PRINCIPAL_TOKEN_ADDRESS, amount);
    }

    //█ Identity Validation Functions ███████████████████████████████████████████████████████████████

    /**
     * @notice Validates username format according to system rules
     * @dev Username must be at least 4 characters, start with a letter, and contain only letters/digits
     * @param username The username string to validate
     */
    function isValidUsername(string memory username) internal pure {
        bytes memory usernameBytes = bytes(username);

        // Check if username length is at least 4 characters
        if (usernameBytes.length < 4) revert ErrorsLib.InvalidUsername(0x01);

        // Check if username begins with a letter
        if (!_isLetter(usernameBytes[0]))
            revert ErrorsLib.InvalidUsername(0x02);

        // Iterate through each character in the username
        for (uint256 i = 0; i < usernameBytes.length; i++) {
            // Check if character is not a digit or letter
            if (!_isDigit(usernameBytes[i]) && !_isLetter(usernameBytes[i])) {
                revert ErrorsLib.InvalidUsername(0x03);
            }
        }
    }

    /**
     * @notice Validates phone number format
     * @dev Phone number must be 6-19 digits only
     * @param _phoneNumber The phone number string to validate
     * @return True if valid phone number format
     */
    function isValidPhoneNumberNumber(
        string memory _phoneNumber
    ) internal pure returns (bool) {
        bytes memory _telephoneNumberBytes = bytes(_phoneNumber);
        if (
            _telephoneNumberBytes.length < 20 &&
            _telephoneNumberBytes.length > 5
        ) {
            revert();
        }
        for (uint256 i = 0; i < _telephoneNumberBytes.length; i++) {
            if (!_isDigit(_telephoneNumberBytes[i])) {
                revert();
            }
        }
        return true;
    }

    /**
     * @notice Validates email address format
     * @dev Checks for proper email structure: prefix(3+ chars) + @ + domain(3+ chars) + . + TLD(2+ chars)
     * @param _email The email address string to validate
     * @return True if valid email format
     */
    function isValidEmail(string memory _email) internal pure returns (bool) {
        bytes memory _emailBytes = bytes(_email);
        uint256 lengthCount = 0;
        bytes1 flagVerify = 0x00;
        for (uint point = 0; point < _emailBytes.length; point++) {
            //step 1 0x00 prefix
            if (flagVerify == 0x00) {
                if (_isOnlyEmailPrefixCharacters(_emailBytes[point])) {
                    lengthCount++;
                } else {
                    if (_isAAt(_emailBytes[point])) {
                        flagVerify = 0x01;
                    } else {
                        revert();
                    }
                }
            }

            //step 2 0x01 count the prefix length
            if (flagVerify == 0x01) {
                if (lengthCount < 3) {
                    revert();
                } else {
                    flagVerify = 0x02;
                    lengthCount = 0;
                    point++;
                }
            }

            //step 3 0x02 domain name
            if (flagVerify == 0x02) {
                if (_isLetter(_emailBytes[point])) {
                    lengthCount++;
                } else {
                    if (_isAPoint(_emailBytes[point])) {
                        flagVerify = 0x03;
                    } else {
                        revert();
                    }
                }
            }

            //step 4 0x03 count the domain name length
            if (flagVerify == 0x03) {
                if (lengthCount < 3) {
                    revert();
                } else {
                    flagVerify = 0x04;
                    lengthCount = 0;
                    point++;
                }
            }

            //step 5 0x04 top level domain
            if (flagVerify == 0x04) {
                if (_isLetter(_emailBytes[point])) {
                    lengthCount++;
                } else {
                    if (_isAPoint(_emailBytes[point])) {
                        if (lengthCount < 2) {
                            revert();
                        } else {
                            lengthCount = 0;
                        }
                    } else {
                        revert();
                    }
                }
            }
        }

        if (flagVerify != 0x04) {
            revert();
        }

        return true;
    }

    /// @dev Checks if a byte represents a digit (0-9)
    function _isDigit(bytes1 character) private pure returns (bool) {
        return (character >= 0x30 && character <= 0x39); // ASCII range for digits 0-9
    }

    /// @dev Checks if a byte represents a letter (A-Z or a-z)
    function _isLetter(bytes1 character) private pure returns (bool) {
        return ((character >= 0x41 && character <= 0x5A) ||
            (character >= 0x61 && character <= 0x7A)); // ASCII ranges for letters A-Z and a-z
    }

    /// @dev Checks if a byte represents any symbol character
    function _isAnySimbol(bytes1 character) private pure returns (bool) {
        return ((character >= 0x21 && character <= 0x2F) || /// @dev includes characters from "!" to "/"
            (character >= 0x3A && character <= 0x40) || /// @dev includes characters from ":" to "@"
            (character >= 0x5B && character <= 0x60) || /// @dev includes characters from "[" to "`"
            (character >= 0x7B && character <= 0x7E)); /// @dev includes characters from "{" to "~"
    }

    /// @dev Checks if a byte is valid for email prefix (letters, digits, and specific symbols)
    function _isOnlyEmailPrefixCharacters(
        bytes1 character
    ) private pure returns (bool) {
        return (_isLetter(character) ||
            _isDigit(character) ||
            (character >= 0x21 && character <= 0x2F) || /// @dev includes characters from "!" to "/"
            (character >= 0x3A && character <= 0x3F) || /// @dev includes characters from ":" to "?"
            (character >= 0x5B && character <= 0x60) || /// @dev includes characters from "[" to "`"
            (character >= 0x7B && character <= 0x7E)); /// @dev includes characters from "{" to "~"
    }

    /// @dev Checks if a byte represents a period/dot character (.)
    function _isAPoint(bytes1 character) private pure returns (bool) {
        return character == 0x2E;
    }

    /// @dev Checks if a byte represents an at symbol (@)
    function _isAAt(bytes1 character) private pure returns (bool) {
        return character == 0x40;
    }

    //█ Username Hashing Functions ███████████████████████████████████████████████████████████████████

    /**
     * @notice Creates a hash of username and random number for pre-registration
     * @dev Used in the commit-reveal scheme to prevent front-running attacks
     * @param _username The username to hash
     * @param _randomNumber Random number to add entropy
     * @return Hash of the username and random number
     */
    function hashUsername(
        string memory _username,
        uint256 _randomNumber
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_username, _randomNumber));
    }

    //█ View Functions - Public Data Access ██████████████████████████████████████████████████████████

    //█ Service Functions ████████████████████████████████████████████████████████████████

    /**
     * @notice Checks if an identity exists in the system
     * @dev Handles both pre-registrations and actual username registrations
     * @param _identity The identity/username to check
     * @return True if the identity exists and is valid
     */
    function verifyIfIdentityExists(
        string memory _identity
    ) public view returns (bool) {
        if (identityDetails[_identity].flagNotAUsername == 0x01) {
            if (
                identityDetails[_identity].owner == address(0) ||
                identityDetails[_identity].expireDate != 0
            ) {
                return false;
            } else {
                return true;
            }
        } else {
            if (identityDetails[_identity].expireDate == 0) {
                return false;
            } else {
                return true;
            }
        }
    }

    /**
     * @notice Strictly verifies if an identity exists and reverts if not found
     * @dev More strict version that reverts instead of returning false
     * @param _username The username to verify
     * @return True if the username exists (will revert if not)
     */
    function strictVerifyIfIdentityExist(
        string memory _username
    ) public view returns (bool) {
        if (identityDetails[_username].flagNotAUsername == 0x01) {
            if (
                identityDetails[_username].owner == address(0) ||
                identityDetails[_username].expireDate != 0
            ) {
                revert();
            } else {
                return true;
            }
        } else {
            if (identityDetails[_username].expireDate == 0) {
                revert();
            } else {
                return true;
            }
        }
    }

    /**
     * @notice Gets the owner address of a registered identity
     * @dev Returns the current owner address for any valid identity
     * @param _username The username to query
     * @return Address of the username owner
     */
    function getOwnerOfIdentity(
        string memory _username
    ) public view returns (address) {
        return identityDetails[_username].owner;
    }

    /**
     * @notice Verifies identity exists and returns owner address
     * @dev Combines strict verification with owner lookup in one call
     * @param _username The username to verify and get owner for
     * @return answer Address of the username owner (reverts if username doesn't exist)
     */
    function verifyStrictAndGetOwnerOfIdentity(
        string memory _username
    ) public view returns (address answer) {
        if (strictVerifyIfIdentityExist(_username)) {
            answer = identityDetails[_username].owner;
        }
    }

    /**
     * @notice Calculates the cost to renew a username registration
     * @dev Pricing varies based on timing and market demand:
     *      - Free if renewed before expiration (within grace period)
     *      - Variable cost based on highest active offer (minimum 500 MATE)
     *      - Fixed 500,000 MATE if renewed more than 1 year before expiration
     * @param _identity The username to calculate renewal price for
     * @return price The cost in MATE tokens to renew the username
     */
    function seePriceToRenew(
        string memory _identity
    ) public view returns (uint256 price) {
        if (identityDetails[_identity].expireDate >= block.timestamp) {
            if (usernameOffers[_identity][0].expireDate != 0) {
                for (
                    uint256 i = 0;
                    i < identityDetails[_identity].offerMaxSlots;
                    i++
                ) {
                    if (
                        usernameOffers[_identity][i].expireDate >
                        block.timestamp &&
                        usernameOffers[_identity][i].offerer != address(0)
                    ) {
                        if (usernameOffers[_identity][i].amount > price) {
                            price = usernameOffers[_identity][i].amount;
                        }
                    }
                }
            }
            if (price == 0) {
                price = 500 * 10 ** 18;
            } else {
                uint256 mateReward = Evvm(evvmAddress.current)
                    .getRewardAmount();
                price = ((price * 5) / 1000) > (500000 * mateReward)
                    ? (500000 * mateReward)
                    : ((price * 5) / 1000);
            }
        } else {
            price = 500_000 * Evvm(evvmAddress.current).getRewardAmount();
        }
    }

    /**
     * @notice Gets the current price to add custom metadata to a username
     * @dev Price is dynamic based on current EVVM reward amount
     * @return price Cost in MATE tokens (10x current reward amount)
     */
    function getPriceToAddCustomMetadata() public view returns (uint256 price) {
        price = 10 * Evvm(evvmAddress.current).getRewardAmount();
    }

    /**
     * @notice Gets the current price to remove a single custom metadata entry
     * @dev Price is dynamic based on current EVVM reward amount
     * @return price Cost in MATE tokens (10x current reward amount)
     */
    function getPriceToRemoveCustomMetadata()
        public
        view
        returns (uint256 price)
    {
        price = 10 * Evvm(evvmAddress.current).getRewardAmount();
    }

    /**
     * @notice Gets the cost to remove all custom metadata entries from a username
     * @dev Cost scales with the number of metadata entries to remove
     * @param _identity The username to calculate flush cost for
     * @return price Total cost in MATE tokens (10x reward amount per metadata entry)
     */
    function getPriceToFlushCustomMetadata(
        string memory _identity
    ) public view returns (uint256 price) {
        price =
            (10 * Evvm(evvmAddress.current).getRewardAmount()) *
            identityDetails[_identity].customMetadataMaxSlots;
    }

    /**
     * @notice Gets the cost to completely remove a username and all its data
     * @dev Includes cost for metadata removal plus base username deletion fee
     * @param _identity The username to calculate deletion cost for
     * @return price Total cost in MATE tokens (metadata flush cost + 1x reward amount)
     */
    function getPriceToFlushUsername(
        string memory _identity
    ) public view returns (uint256 price) {
        price =
            ((10 * Evvm(evvmAddress.current).getRewardAmount()) *
                identityDetails[_identity].customMetadataMaxSlots) +
            Evvm(evvmAddress.current).getRewardAmount();
    }

    //█ User Management Functions ████████████████████████████████████████████████████████████████████

    /**
     * @notice Checks if a nonce has been used by a specific user
     * @dev Prevents replay attacks by tracking used nonces per user
     * @param _user Address of the user to check
     * @param _nonce Nonce value to verify
     * @return True if the nonce has been used, false if still available
     */
    function checkIfNameServiceNonceIsAvailable(
        address _user,
        uint256 _nonce
    ) public view returns (bool) {
        return nameServiceNonce[_user][_nonce];
    }

    //█ Identity Availability Functions ██████████████████████████████████████████████████████████████

    /**
     * @notice Checks if a username is available for registration
     * @dev A username is available if it was never registered or has been expired for 60+ days
     * @param _username The username to check availability for
     * @return True if the username is available for registration
     */
    function isUsernameAvailable(
        string memory _username
    ) public view returns (bool) {
        if (identityDetails[_username].expireDate == 0) {
            return true;
        } else {
            return
                identityDetails[_username].expireDate + 60 days <
                block.timestamp;
        }
    }

    /**
     * @notice Gets basic identity information (owner and expiration date)
     * @dev Returns essential metadata for quick identity verification
     * @param _username The username to get basic info for
     * @return Owner address and expiration timestamp
     */
    function getIdentityBasicMetadata(
        string memory _username
    ) public view returns (address, uint256) {
        return (
            identityDetails[_username].owner,
            identityDetails[_username].expireDate
        );
    }

    /**
     * @notice Gets the number of custom metadata entries for a username
     * @dev Returns the count of metadata slots currently used
     * @param _username The username to count metadata for
     * @return Number of custom metadata entries
     */
    function getAmountOfCustomMetadata(
        string memory _username
    ) public view returns (uint256) {
        return identityDetails[_username].customMetadataMaxSlots;
    }

    /**
     * @notice Retrieves all custom metadata entries for a username
     * @dev Returns an array containing all metadata strings in order
     * @param _username The username to get metadata for
     * @return Array of all custom metadata strings
     */
    function getFullCustomMetadataOfIdentity(
        string memory _username
    ) public view returns (string[] memory) {
        string[] memory _customMetadata = new string[](
            identityDetails[_username].customMetadataMaxSlots
        );
        for (
            uint256 i = 0;
            i < identityDetails[_username].customMetadataMaxSlots;
            i++
        ) {
            _customMetadata[i] = identityCustomMetadata[_username][i];
        }
        return _customMetadata;
    }

    /**
     * @notice Gets a specific custom metadata entry by index
     * @dev Retrieves metadata at a specific slot position
     * @param _username The username to get metadata from
     * @param _key The index of the metadata entry to retrieve
     * @return The metadata string at the specified index
     */
    function getSingleCustomMetadataOfIdentity(
        string memory _username,
        uint256 _key
    ) public view returns (string memory) {
        return identityCustomMetadata[_username][_key];
    }

    /**
     * @notice Gets the maximum number of metadata slots available for a username
     * @dev Returns the total capacity for custom metadata entries
     * @param _username The username to check metadata capacity for
     * @return Maximum number of metadata slots
     */
    function getCustomMetadataMaxSlotsOfIdentity(
        string memory _username
    ) public view returns (uint256) {
        return identityDetails[_username].customMetadataMaxSlots;
    }

    //█ Username Marketplace Functions ███████████████████████████████████████████████████████████████

    /**
     * @notice Gets all offers made for a specific username
     * @dev Returns both active and expired offers that haven't been withdrawn
     * @param _username The username to get offers for
     * @return offers Array of all offer metadata structures
     */
    function getOffersOfUsername(
        string memory _username
    ) public view returns (OfferMetadata[] memory offers) {
        offers = new OfferMetadata[](identityDetails[_username].offerMaxSlots);

        for (uint256 i = 0; i < identityDetails[_username].offerMaxSlots; i++) {
            offers[i] = usernameOffers[_username][i];
        }
    }

    /**
     * @notice Gets a specific offer for a username by offer ID
     * @dev Retrieves detailed information about a particular offer
     * @param _username The username to get the offer from
     * @param _offerID The ID/index of the specific offer
     * @return offer The complete offer metadata structure
     */
    function getSingleOfferOfUsername(
        string memory _username,
        uint256 _offerID
    ) public view returns (OfferMetadata memory offer) {
        return usernameOffers[_username][_offerID];
    }

    /**
     * @notice Counts the total number of offers made for a username
     * @dev Iterates through offers to find the actual count of non-empty slots
     * @param _username The username to count offers for
     * @return length Total number of offers that have been made
     */
    function getLengthOfOffersUsername(
        string memory _username
    ) public view returns (uint256 length) {
        do {
            length++;
        } while (usernameOffers[_username][length].expireDate != 0);
    }

    /**
     * @notice Gets the expiration date of a username registration
     * @dev Returns the timestamp when the username registration expires
     * @param _identity The username to check expiration for
     * @return The expiration timestamp in seconds since Unix epoch
     */
    function getExpireDateOfIdentity(
        string memory _identity
    ) public view returns (uint256) {
        return identityDetails[_identity].expireDate;
    }

    /**
     * @notice Gets the current price for registering a new username
     * @dev Price is dynamic and based on current EVVM reward amount (100x reward)
     * @return The current registration price in MATE tokens
     */
    function getPricePerRegistration() public view returns (uint256) {
        return Evvm(evvmAddress.current).getRewardAmount() * 100;
    }

    //█ Administrative Getters ███████████████████████████████████████████████████████████████████████

    /**
     * @notice Gets the current admin address
     * @dev Returns the address with administrative privileges
     * @return The current admin address
     */
    function getAdmin() public view returns (address) {
        return admin.current;
    }

    /**
     * @notice Gets complete admin information including pending proposals
     * @dev Returns current admin, proposed admin, and proposal acceptance deadline
     * @return currentAdmin Current administrative address
     * @return proposalAdmin Proposed new admin address (if any)
     * @return timeToAcceptAdmin Timestamp when proposal can be accepted
     */
    function getAdminFullDetails()
        public
        view
        returns (
            address currentAdmin,
            address proposalAdmin,
            uint256 timeToAcceptAdmin
        )
    {
        return (admin.current, admin.proposal, admin.timeToAccept);
    }

    /**
     * @notice Gets information about pending token withdrawal proposals
     * @dev Returns proposed withdrawal amount and acceptance deadline
     * @return proposalAmountToWithdrawTokens Proposed withdrawal amount in MATE tokens
     * @return timeToAcceptAmountToWithdrawTokens Timestamp when proposal can be executed
     */
    function getProposedWithdrawAmountFullDetails()
        public
        view
        returns (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        )
    {
        return (
            amountToWithdrawTokens.proposal,
            amountToWithdrawTokens.timeToAccept
        );
    }

    /**
     * @notice Gets the current EVVM contract address
     * @dev Returns the address of the EVVM contract used for payment processing
     * @return The current EVVM contract address
     */
    function getEvvmAddress() public view returns (address) {
        return evvmAddress.current;
    }

    /**
     * @notice Gets complete EVVM address information including pending proposals
     * @dev Returns current EVVM address, proposed address, and proposal acceptance deadline
     * @return currentEvvmAddress Current EVVM contract address
     * @return proposalEvvmAddress Proposed new EVVM address (if any)
     * @return timeToAcceptEvvmAddress Timestamp when proposal can be accepted
     */
    function getEvvmAddressFullDetails()
        public
        view
        returns (
            address currentEvvmAddress,
            address proposalEvvmAddress,
            uint256 timeToAcceptEvvmAddress
        )
    {
        return (
            evvmAddress.current,
            evvmAddress.proposal,
            evvmAddress.timeToAccept
        );
    }
}
