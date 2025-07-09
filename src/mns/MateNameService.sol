// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;
/*  

███╗   ███╗███╗   ██╗███████╗
████╗ ████║████╗  ██║██╔════╝
██╔████╔██║██╔██╗ ██║███████╗
██║╚██╔╝██║██║╚██╗██║╚════██║
██║ ╚═╝ ██║██║ ╚████║███████║
╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
 *  @title MATE Name Service
 *  @author jistro.eth ariutokintumi.eth
 *  @notice This contract is designed to register and manage usernames for
 *          the MATE metaprotocol
 */

import {Evvm} from  "@EVVM/testnet/evvm/Evvm.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SignatureRecover} from "@EVVM/libraries/SignatureRecover.sol";
import {AdvancedStrings} from "@EVVM/libraries/AdvancedStrings.sol";

contract MateNameService {
    using SignatureRecover for *;
    using AdvancedStrings for *;

    error InvalidSignature();
    error InvalidUsername();
    error InvalidOwner();
    error InvalidEmailOrPhoneNumber();
    error HasNoCustomMetadata();
    error InvalidSignatureOnMNS();
    error UsernameAlreadyRegistered();
    error NonceAlreadyUsed();
    error checkIfUsernameOwner();
    error checkIfUsernameHasWindowTime();
    error OfferAlreadyWithdrawn();
    error OfferExpired();
    error Logic(uint256);

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

    struct BoolTypeProposal {
        bool flag;
        uint256 timeToAcceptChange;
    }
    struct IdentityBaseMetadata {
        address owner;
        uint256 expireDate;
        uint256 customMetadataMaxSlots;
        uint256 offerMaxSlots;
        bytes1 flagNotAUsername;
    }

    mapping(string username => IdentityBaseMetadata basicMetadata)
        private identityDetails;

    struct OfferMetadata {
        address offerer;
        uint256 expireDate;
        uint256 amount;
    }

    mapping(string username => mapping(uint256 id => OfferMetadata))
        private usernameOffers;

    mapping(string username => mapping(uint256 numberKey => string customValue))
        private identityCustomMetadata;

    mapping(address => mapping(uint256 => bool)) private mateNameServiceNonce;

    UintTypeProposal amountToWithdrawTokens;

    AddressTypeProposal evvmAddress;

    AddressTypeProposal admin;


    address private constant MATE_TOKEN =
        0x0000000000000000000000000000000000000001;

    /// @notice In epoch time, 1721865600 is 25/jul/2024 at 00:00:00
    uint256 private constant PROMOTION_END_DATE = 1721865600;

    uint256 private mateTokenLockedForWithdrawOffers;

    modifier onlyAdmin() {
        if (msg.sender != admin.current) {
            revert InvalidOwner();
        }
        _;
    }

    modifier onlyOwnerOfIdentity(address _user, string memory _identity) {
        if (identityDetails[_identity].owner != _user) {
            revert checkIfUsernameOwner();
        }
        _;
    }

    modifier verifyIfNonceIsAvailable(address _user, uint256 _nonce) {
        if (mateNameServiceNonce[_user][_nonce]) {
            revert NonceAlreadyUsed();
        }
        _;
    }

    constructor(address _evvmAddress, address _initialOwner) {
        evvmAddress.current = _evvmAddress;
        admin.current = _initialOwner;
    }

    /**
     *  @notice This function is used to pre-register a username to avoid
     *          front-running attacks.
     *  @param _user the address of the user who wants to pre-register
     *               the username
     *  @param _nonce the nonce of the user
     *  @param _hashUsername the hash of pre-registered username
     *  @param _priorityFeeForFisher the priority fee for the fisher who will include
     *                       the transaction
     *  @param _signature the signature of the transaction of the priority fee
     *
     *  @notice if doesn't have a priority fee the next parameters are not necessary
     *
     *  @param _nonce_Evvm the nonce of the user in the Evvm
     *  @param _priority_Evvm the priority of the transaction in the
     *                               Evvm's payMateStaker function
     *  @param _signature_Evvm the signature of the transaction in the
     *                                payMateStaker function in the Evvm
     */
    function preRegistrationUsername(
        address _user,
        uint256 _nonce,
        bytes32 _hashUsername,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) public verifyIfNonceIsAvailable(_user, _nonce) {
        if (
            !verifyMessageSignedForPreRegistrationUsername(
                _user,
                _hashUsername,
                _nonce,
                _signature
            )
        ) {
            revert InvalidSignatureOnMNS();
        }

        if (_priorityFeeForFisher > 0) {
            makePay(
                _user,
                _nonce_Evvm,
                _priorityFeeForFisher,
                0,
                _priority_Evvm,
                _signature_Evvm
            );
        }
        /// concatenamos @ con el hash del username para evitar que se pueda registrar un username que no sea un hash
        string memory _key = string.concat(
            "@",
            AdvancedStrings.bytes32ToString(_hashUsername)
        );

        identityDetails[_key] = IdentityBaseMetadata({
            owner: _user,
            expireDate: block.timestamp + 30 minutes,
            customMetadataMaxSlots: 0,
            offerMaxSlots: 0,
            flagNotAUsername: 0x01
        });

        mateNameServiceNonce[_user][_nonce] = true;

        if (Evvm(evvmAddress.current).isMateStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                Evvm(evvmAddress.current).seeMateReward() +
                    _priorityFeeForFisher
            );
        }
    }

    /**
     *  @notice This function is used to register a username
     *  @param _user the address of the user who wants to register
     *  @param _nonce the nonce of the user
     *  @param _username the username to register
     *  @param _clowNumber the random number of the pre-registration
     *                     hash of the username to verify if the user
     *                     is the owner of the pre-registration hash
     *  @param _signature the signature of the transaction
     *  @param _priorityFeeForFisher the priority fee for the fisher who will include
     *  @param _nonce_Evvm the nonce of the user in the Evvm
     *  @param _priority_Evvm the priority of the transaction in the
     *                               Evvm's payMateStaker function
     *  @param _signature_Evvm the signature of the transaction in the
     *                                payMateStaker function in the Evvm
     */
    function registrationUsername(
        address _user,
        uint256 _nonce,
        string memory _username,
        uint256 _clowNumber,
        bytes memory _signature,
        uint256 _priorityFeeForFisher,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) public verifyIfNonceIsAvailable(_user, _nonce) {
        if (admin.current != _user) {
            if (!isValidUsername(_username)) {
                revert InvalidUsername();
            }
        }

        if (!isUsernameAvailable(_username)) {
            revert UsernameAlreadyRegistered();
        }

        if (
            !verifyMessageSignedForRegistrationUsername(
                _user,
                _username,
                _clowNumber,
                _nonce,
                _signature
            )
        ) {
            revert InvalidSignatureOnMNS();
        }

        makePay(
            _user,
            _nonce_Evvm,
            getPricePerRegistration(),
            _priorityFeeForFisher,
            _priority_Evvm,
            _signature_Evvm
        );

        string memory _key = string.concat(
            "@",
            AdvancedStrings.bytes32ToString(
                hashUsername(_username, _clowNumber)
            )
        );

        if (
            identityDetails[_key].owner != _user ||
            identityDetails[_key].expireDate > block.timestamp
        ) {
            revert();
        }

        identityDetails[_username] = IdentityBaseMetadata({
            owner: _user,
            expireDate: block.timestamp + 366 days,
            customMetadataMaxSlots: 0,
            offerMaxSlots: 0,
            flagNotAUsername: 0x00
        });

        mateNameServiceNonce[_user][_nonce] = true;

        if (Evvm(evvmAddress.current).isMateStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (50 * Evvm(evvmAddress.current).seeMateReward()) +
                    _priorityFeeForFisher
            );
        }

        delete identityDetails[_key];
    }


    function makeOffer(
        address _user,
        uint256 _nonce,
        string memory _username,
        uint256 _amount,
        uint256 _expireDate,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) public verifyIfNonceIsAvailable(_user, _nonce) returns (uint256 offerID) {
        if (
            identityDetails[_username].flagNotAUsername == 0x01 ||
            !verifyIfIdentityExists(_username) ||
            _amount == 0 ||
            _expireDate <= block.timestamp
        ) {
            revert();
        }
        if (
            !verifyMessageSignedForMakeOffer(
                _user,
                _username,
                _expireDate,
                _amount,
                _nonce,
                _signature
            )
        ) {
            revert InvalidSignature();
        }

        makePay(
            _user,
            _nonce_Evvm,
            _amount,
            _priorityFeeForFisher,
            _priority_Evvm,
            _signature_Evvm
        );

        while (usernameOffers[_username][offerID].offerer != address(0)) {
            offerID++;
        }

        usernameOffers[_username][offerID] = OfferMetadata({
            offerer: _user,
            expireDate: _expireDate,
            amount: ((_amount * 995) / 1000) /// calcula el 99.5% del valor de la oferta
        });

        makeCaPay(
            msg.sender,
            Evvm(evvmAddress.current).seeMateReward() +
                ((_amount * 125) / 100_000) +
                _priorityFeeForFisher
        );
        mateTokenLockedForWithdrawOffers +=
            ((_amount * 995) / 1000) +
            (_amount / 800);

        if (offerID > identityDetails[_username].offerMaxSlots) {
            identityDetails[_username].offerMaxSlots++;
        } else if (identityDetails[_username].offerMaxSlots == 0) {
            identityDetails[_username].offerMaxSlots++;
        }

        mateNameServiceNonce[_user][_nonce] = true;
    }

    function withdrawOffer(
        address _user,
        uint256 _nonce,
        string memory _username,
        uint256 _offerID,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) public verifyIfNonceIsAvailable(_user, _nonce) {
        if (
            usernameOffers[_username][_offerID].offerer != _user ||
            !verifyMessageSignedForWithdrawOffer(
                _user,
                _username,
                _offerID,
                _nonce,
                _signature
            )
        ) {
            revert();
        }

        if (_priorityFeeForFisher > 0) {
            makePay(
                _user,
                _nonce_Evvm,
                _priorityFeeForFisher,
                0,
                _priority_Evvm,
                _signature_Evvm
            );
        }

        makeCaPay(_user, usernameOffers[_username][_offerID].amount);

        usernameOffers[_username][_offerID].offerer = address(0);

        makeCaPay(
            msg.sender,
            Evvm(evvmAddress.current).seeMateReward() +
                //obtenemos el 0.5% y dividimos entre 4 para obtener el 0.125%
                //+ ((usernameOffers[_username][_offerID].amount  * 1 / 199)/4)
                //mas simplificado
                ((usernameOffers[_username][_offerID].amount * 1) / 796) +
                _priorityFeeForFisher
        );

        mateTokenLockedForWithdrawOffers -=
            (usernameOffers[_username][_offerID].amount) +
            (((usernameOffers[_username][_offerID].amount * 1) / 199) / 4);

        mateNameServiceNonce[_user][_nonce] = true;
    }

    /**
     *  @notice This function is used to accept an offer for a username
     *  @param _user the address of the user who owns the username
     *  @param _nonce the nonce of the user
     *  @param _username the username to accept the offer
     *  @param _offerID the ID of the offer to accept
     *  @param _priorityFeeForFisher the priority fee for the fisher who will include the
     *                       transaction
     *  @param _signature the signature of the transaction
     *
     *  @notice if doesn't have a priority fee the next parameters are not necessary
     *
     *  @param _nonce_Evvm the nonce of the user in the Evvm
     *  @param _priority_Evvm the priority of the transaction in the
     *                               Evvm's payMateStaker function
     *  @param _signature_Evvm the signature of the transaction in the
     *                                payMateStaker function in the Evvm
     */
    function acceptOffer(
        address _user,
        uint256 _nonce,
        string memory _username,
        uint256 _offerID,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    )
        public
        onlyOwnerOfIdentity(_user, _username)
        verifyIfNonceIsAvailable(_user, _nonce)
    {
        if (
            usernameOffers[_username][_offerID].offerer == address(0) ||
            usernameOffers[_username][_offerID].expireDate < block.timestamp
        ) {
            revert();
        }
        if (
            !verifyMessageSignedForAcceptOffer(
                _user,
                _username,
                _offerID,
                _nonce,
                _signature
            )
        ) {
            revert InvalidSignature();
        }

        if (_priorityFeeForFisher > 0) {
            makePay(
                _user,
                _nonce_Evvm,
                _priorityFeeForFisher,
                0,
                _priority_Evvm,
                _signature_Evvm
            );
        }

        makeCaPay(_user, usernameOffers[_username][_offerID].amount);

        identityDetails[_username].owner = usernameOffers[_username][_offerID]
            .offerer;

        usernameOffers[_username][_offerID].offerer = address(0);

        if (Evvm(evvmAddress.current).isMateStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (Evvm(evvmAddress.current).seeMateReward()) +
                    (((usernameOffers[_username][_offerID].amount * 1) / 199) /
                        4) +
                    _priorityFeeForFisher
            );
        }

        mateTokenLockedForWithdrawOffers -=
            (usernameOffers[_username][_offerID].amount) +
            (((usernameOffers[_username][_offerID].amount * 1) / 199) / 4);

        mateNameServiceNonce[_user][_nonce] = true;
    }

    /**
     *  @notice This function is used to renew a username
     *
     *  @custom:important
     *      if the owner of the username wants to renew the
     *      username one year before the expiration date, the
     *      price is 0 MATE only for a limited time, after that
     *      the price is consultable in the seePriceToRenew function
     *      but if the owner of the username wants to renew more than
     *      one year before the expiration date, the price is 500,000
     *      MATE and can be renewed up to 100 years
     *
     *  @param _user the address of the user who owns the username
     *  @param _nonce the nonce of the user
     *  @param _username the username to renew
     *  @param _priorityFeeForFisher the priority fee for the fisher who will include the
     *                       transaction
     *  @param _signature the signature of the transaction
     *  @param _nonce_Evvm the nonce of the user in the Evvm
     *  @param _priority_Evvm the priority of the transaction in the
     *                               Evvm's payMateStaker function
     *  @param _signature_Evvm the signature of the transaction in the
     *                                payMateStaker function in the Evvm
     */
    function renewUsername(
        address _user,
        uint256 _nonce,
        string memory _username,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    )
        public
        onlyOwnerOfIdentity(_user, _username)
        verifyIfNonceIsAvailable(_user, _nonce)
    {
        if (
            identityDetails[_username].flagNotAUsername == 0x01 ||
            !verifyMessageSignedForRenewUsername(
                _user,
                _username,
                _nonce,
                _signature
            )
        ) {
            revert();
        }
        if (
            identityDetails[_username].expireDate > block.timestamp + 36500 days
        ) {
            revert();
        }

        uint256 priceOfRenew = seePriceToRenew(_username);

        makePay(
            _user,
            _nonce_Evvm,
            priceOfRenew,
            _priorityFeeForFisher,
            _priority_Evvm,
            _signature_Evvm
        );

        if (Evvm(evvmAddress.current).isMateStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                Evvm(evvmAddress.current).seeMateReward() +
                    ((priceOfRenew * 50) / 100) + //? no estamos siendo muy generosos con el priority fee
                    _priorityFeeForFisher
            );
        }

        identityDetails[_username].expireDate += 366 days;
        mateNameServiceNonce[_user][_nonce] = true;
    }

    /* 
    * How to use identityCustomMetadata:
    *
    * identityCustomMetadata["username"][key] = "value";
    *
    * Parameters:
    * 
    * - key (numberKey):
    *   Should be treated as a nonce (unique number) to avoid overwriting existing values.
    *   The value 0 is used as a header to check for the absence of a value in case the user
    *   does not enter one.
    *
    * - value (customValue):
    *   Is a text string that allows storing any type of data.
    *   The data follows a standard to facilitate reading, although it is not mandatory
    *   to fully comply with it.
    *
    * Standard value format:
    * [schema]:[subschema]>[value]
    *
    * Examples:
    * memberOf:>EVVM
    * socialMedia:x     >jistro       // LinkedIn without subschema
    * email:dev   >jistro@evvm.org    // Email with "dev" subschema
    * email:callme>contact@jistro.xyz  // Email with "callme" subschema
    *
    * Important notes:
    * - 'schema' is based on https://schema.org/docs/schemas.html
    * - ':' is the separator between schema and subschema
    * - '>' is the separator between metadata and value
    * - If 'schema' or 'subschema' have fewer than 5 characters, they should be padded with spaces:
    *   Example: vk   :job  >jane-doe
    * - In case of social networks, the 'schema' should be "socialMedia" and the 'subschema' should be the social network name
    */
    function addCustomMetadata(
        address _user,
        uint256 _nonce,
        string memory _identity,
        string memory _value,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm_forAddCustomMetadata,
        bool _priority_Evvm_forAddCustomMetadata,
        bytes memory _signature_Evvm_forAddCustomMetadata
    )
        public
        onlyOwnerOfIdentity(_user, _identity)
        verifyIfNonceIsAvailable(_user, _nonce)
    {
        if (
            !verifyMessageSignedForAddCustomMetadata(
                _user,
                _identity,
                _value,
                _nonce,
                _signature
            )
        ) {
            revert();
        }

        if (bytes(_value).length == 0) {
            revert();
        }

        makePay(
            _user,
            _nonce_Evvm_forAddCustomMetadata,
            getPriceToAddCustomMetadata(),
            _priorityFeeForFisher,
            _priority_Evvm_forAddCustomMetadata,
            _signature_Evvm_forAddCustomMetadata
        );

        if (Evvm(evvmAddress.current).isMateStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (5 * Evvm(evvmAddress.current).seeMateReward()) +
                    ((getPriceToAddCustomMetadata() * 50) / 100) +
                    _priorityFeeForFisher
            );
        }

        identityCustomMetadata[_identity][
            identityDetails[_identity].customMetadataMaxSlots
        ] = _value;
        identityDetails[_identity].customMetadataMaxSlots++;
        mateNameServiceNonce[_user][_nonce] = true;
    }

    function removeCustomMetadata(
        address _user,
        uint256 _nonce,
        string memory _identity,
        uint256 _key,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    )
        public
        onlyOwnerOfIdentity(_user, _identity)
        verifyIfNonceIsAvailable(_user, _nonce)
    {
        if (
            !verifyMessageSignedForRemoveCustomMetadata(
                _user,
                _identity,
                _key,
                _nonce,
                _signature
            )
        ) {
            revert InvalidSignature();
        }

        //check if the key is greater than the number of custom metadata
        if (identityDetails[_identity].customMetadataMaxSlots <= _key) {
            revert();
        }

        makePay(
            _user,
            _nonce_Evvm,
            getPriceToRemoveCustomMetadata(),
            _priorityFeeForFisher,
            _priority_Evvm,
            _signature_Evvm
        );

        //si es el ultimo elemento
        if (identityDetails[_identity].customMetadataMaxSlots == _key) {
            delete identityCustomMetadata[_identity][_key];
        } else {
            for (
                uint256 i = _key;
                i < identityDetails[_identity].customMetadataMaxSlots;
                i++
            ) {
                identityCustomMetadata[_identity][i] = identityCustomMetadata[
                    _identity
                ][i + 1];
            }
            delete identityCustomMetadata[_identity][
                identityDetails[_identity].customMetadataMaxSlots
            ];
        }
        identityDetails[_identity].customMetadataMaxSlots--;
        mateNameServiceNonce[_user][_nonce] = true;
        if (Evvm(evvmAddress.current).isMateStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                (5 * Evvm(evvmAddress.current).seeMateReward()) +
                    _priorityFeeForFisher
            );
        }
    }

    function flushCustomMetadata(
        address _user,
        uint256 _nonce,
        string memory _identity,
        uint256 _priorityFeeForFisher,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    )
        public
        onlyOwnerOfIdentity(_user, _identity)
        verifyIfNonceIsAvailable(_user, _nonce)
    {
        if (
            !verifyMessageSignedForFlushCustomMetadata(
                _user,
                _identity,
                _nonce,
                _signature
            )
        ) {
            revert InvalidSignatureOnMNS();
        }

        if (identityDetails[_identity].customMetadataMaxSlots == 0) {
            revert HasNoCustomMetadata();
        }

        makePay(
            _user,
            _nonce_Evvm,
            getPriceToFlushCustomMetadata(_identity),
            _priorityFeeForFisher,
            _priority_Evvm,
            _signature_Evvm
        );

        for (
            uint256 i = 0;
            i < identityDetails[_identity].customMetadataMaxSlots;
            i++
        ) {
            delete identityCustomMetadata[_identity][i];
        }

        if (Evvm(evvmAddress.current).isMateStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                ((5 * Evvm(evvmAddress.current).seeMateReward()) *
                    identityDetails[_identity].customMetadataMaxSlots) +
                    _priorityFeeForFisher
            );
        }

        identityDetails[_identity].customMetadataMaxSlots = 0;
        mateNameServiceNonce[_user][_nonce] = true;
    }

    function flushUsername(
        address _user,
        string memory _identity,
        uint256 _priorityFeeForFisher,
        uint256 _nonce,
        bytes memory _signature,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    )
        public
        verifyIfNonceIsAvailable(_user, _nonce)
        onlyOwnerOfIdentity(_user, _identity)
    {
        if (
            block.timestamp >= identityDetails[_identity].expireDate ||
            identityDetails[_identity].flagNotAUsername == 0x01 ||
            !verifyMessageSignedForFlushUsername(
                _user,
                _identity,
                _nonce,
                _signature
            )
        ) {
            revert Logic(1);
        }

        makePay(
            _user,
            _nonce_Evvm,
            getPriceToFlushUsername(_identity),
            _priorityFeeForFisher,
            _priority_Evvm,
            _signature_Evvm
        );

        for (
            uint256 i = 0;
            i < identityDetails[_identity].customMetadataMaxSlots;
            i++
        ) {
            delete identityCustomMetadata[_identity][i];
        }

        makeCaPay(
            msg.sender,
            ((5 * Evvm(evvmAddress.current).seeMateReward()) *
                identityDetails[_identity].customMetadataMaxSlots) +
                _priorityFeeForFisher
        );

        identityDetails[_identity] = IdentityBaseMetadata({
            owner: address(0),
            expireDate: 0,
            customMetadataMaxSlots: 0,
            offerMaxSlots: identityDetails[_identity].offerMaxSlots,
            flagNotAUsername: 0x00
        });
        mateNameServiceNonce[msg.sender][_nonce_Evvm] = true;
    }

    //█Tools for admin█████████████████████████████████████████████████████████████████████████████

    function proposeAdmin(address _adminToPropose) public onlyAdmin {
        if (_adminToPropose == address(0) || _adminToPropose == admin.current) {
            revert();
        }

        admin.proposal = _adminToPropose;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    function cancelProposeAdmin() public onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

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

    function proposeWithdrawMateTokens(uint256 _amount) public onlyAdmin {
        if (
            Evvm(evvmAddress.current).seeBalance(
                address(this),
                MATE_TOKEN
            ) -
                (5083 +
                    Evvm(evvmAddress.current).seeMateReward() +
                    mateTokenLockedForWithdrawOffers) <
            _amount ||
            _amount == 0
        ) {
            revert();
        }

        amountToWithdrawTokens.proposal = _amount;
        amountToWithdrawTokens.timeToAccept = block.timestamp + 1 days;
    }

    function cancelWithdrawMateTokens() public onlyAdmin {
        amountToWithdrawTokens.proposal = 0;
        amountToWithdrawTokens.timeToAccept = 0;
    }

    function claimWithdrawMateTokens() public onlyAdmin {
        if (block.timestamp < amountToWithdrawTokens.timeToAccept) {
            revert();
        }

        makeCaPay(admin.current, amountToWithdrawTokens.proposal);

        amountToWithdrawTokens.proposal = 0;
        amountToWithdrawTokens.timeToAccept = 0;
    }

    function proposeChangeEvvmAddress(
        address _newEvvmAddress
    ) public onlyAdmin {
        if (_newEvvmAddress == address(0)) {
            revert();
        }
        evvmAddress.proposal = _newEvvmAddress;
        evvmAddress.timeToAccept = block.timestamp + 1 days;
    }

    function cancelChangeEvvmAddress() public onlyAdmin {
        evvmAddress.proposal = address(0);
        evvmAddress.timeToAccept = 0;
    }

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
    //█Tools███████████████████████████████████████████████████████████████████████████████████████

    //█Tools for Evvm payment████████████████████

    function makePay(
        address _user_Evvm,
        uint256 _nonce_Evvm,
        uint256 _ammount_Evvm,
        uint256 _priorityFee_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) internal {
        if (_priority_Evvm) {
            Evvm(evvmAddress.current).payMateStaking_async(
                _user_Evvm,
                address(this),
                "",
                MATE_TOKEN,
                _ammount_Evvm,
                _priorityFee_Evvm,
                _nonce_Evvm,
                address(this),
                _signature_Evvm
            );
        } else {
            Evvm(evvmAddress.current).payMateStaking_sync(
                _user_Evvm,
                address(this),
                "",
                MATE_TOKEN,
                _ammount_Evvm,
                _priorityFee_Evvm,
                address(this),
                _signature_Evvm
            );
        }
    }

    function makeCaPay(address _user_Evvm, uint256 _ammount_Evvm) internal {
        Evvm(evvmAddress.current).caPay(
            _user_Evvm,
            MATE_TOKEN,
            _ammount_Evvm
        );
    }

    //█Tools for identity validation███████████████████████████████████████████████████████████████
    function isValidUsername(
        string memory username
    ) internal pure returns (bool) {
        bytes memory usernameBytes = bytes(username);

        // Check if username length is at least 4 characters
        if (usernameBytes.length < 4) {
            revert();
        }

        // Check if username begins with a letter
        if (!_isLetter(usernameBytes[0])) {
            revert();
        }

        // Iterate through each character in the username
        for (uint256 i = 0; i < usernameBytes.length; i++) {
            // Check if character is not a digit or letter
            if (!_isDigit(usernameBytes[i]) && !_isLetter(usernameBytes[i])) {
                revert();
            }
        }

        return true;
    }

    function _isDigit(bytes1 character) private pure returns (bool) {
        return (character >= 0x30 && character <= 0x39); // ASCII range for digits 0-9
    }

    function _isLetter(bytes1 character) private pure returns (bool) {
        return ((character >= 0x41 && character <= 0x5A) ||
            (character >= 0x61 && character <= 0x7A)); // ASCII ranges for letters A-Z and a-z
    }

    function _isAnySimbol(bytes1 character) private pure returns (bool) {
        return ((character >= 0x21 && character <= 0x2F) || /// @dev includes characters from "!" to "/"
            (character >= 0x3A && character <= 0x40) || /// @dev includes characters from ":" to "@"
            (character >= 0x5B && character <= 0x60) || /// @dev includes characters from "[" to "`"
            (character >= 0x7B && character <= 0x7E)); /// @dev includes characters from "{" to "~"
    }

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

    function _isAPoint(bytes1 character) private pure returns (bool) {
        return character == 0x2E;
    }

    function _isAAt(bytes1 character) private pure returns (bool) {
        return character == 0x40;
    }

    //█Tools for username hash█████████████████████████████████████████████████████████████████████

    function hashUsername(
        string memory _username,
        uint256 _randomNumber
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_username, _randomNumber));
    }

    //█Signature functions█████████████████████████████████████████████████████████████████████████
    function verifyMessageSignedForPreRegistrationUsername(
        address signer,
        bytes32 _hashUsername,
        uint256 _mateNameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "393b9c6f",
                    ",",
                    AdvancedStrings.bytes32ToString(_hashUsername),
                    ",",
                    Strings.toString(_mateNameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForRegistrationUsername(
        address signer,
        string memory _username,
        uint256 _clowNumber,
        uint256 _mateNameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "d134f8b4",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_clowNumber),
                    ",",
                    Strings.toString(_mateNameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForMakeOffer(
        address signer,
        string memory _username,
        uint256 _dateExpire,
        uint256 _amount,
        uint256 _mateNameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "52649c2e",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_dateExpire),
                    ",",
                    Strings.toString(_amount),
                    ",",
                    Strings.toString(_mateNameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForWithdrawOffer(
        address signer,
        string memory _username,
        uint256 _offerId,
        uint256 _mateNameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "21811609",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_offerId),
                    ",",
                    Strings.toString(_mateNameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForAcceptOffer(
        address signer,
        string memory _username,
        uint256 _offerId,
        uint256 _mateNameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "ae36fe72", //methodIdentifier
                    ",",
                    _username,
                    ",",
                    Strings.toString(_offerId),
                    ",",
                    Strings.toString(_mateNameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForRenewUsername(
        address signer,
        string memory _username,
        uint256 _mateNameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "f1747483",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_mateNameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForAddCustomMetadata(
        address signer,
        string memory _username,
        string memory _value,
        uint256 _mateNameServiceNonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "e6efeffa",
                    ",",
                    _username,
                    ",",
                    _value,
                    ",",
                    Strings.toString(_mateNameServiceNonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForRemoveCustomMetadata(
        address signer,
        string memory _username,
        uint256 _key,
        uint256 _nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "8001a999",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_key),
                    ",",
                    Strings.toString(_nonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForFlushCustomMetadata(
        address signer,
        string memory _username,
        uint256 _nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "3e7899a1",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_nonce)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForFlushUsername(
        address signer,
        string memory _username,
        uint256 _nonce,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                string.concat(
                    "d22c816c",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_nonce)
                ),
                signature,
                signer
            );
    }

    //█Getters█████████████████████████████████████████████████████████████████████████████████████

    //█Getters for services██████████████████████████████████████████████████████████████

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

    function getOwnerOfIdentity(
        string memory _username
    ) public view returns (address) {
        return identityDetails[_username].owner;
    }

    function verifyStrictAndGetOwnerOfIdentity(
        string memory _username
    ) public view returns (address answer) {
        if (strictVerifyIfIdentityExist(_username)) {
            answer = identityDetails[_username].owner;
        }
    }

    /**
     *  @notice This function is used to see the price to renew a username
     *  @param _identity the username to see the price to renew
     *  @return price the price to renew the username
     */
    function seePriceToRenew(
        string memory _identity
    ) public view returns (uint256 price) {
        ///verifica si es menor a 366 días
        if (identityDetails[_identity].expireDate >= block.timestamp) {
            if (usernameOffers[_identity][0].expireDate != 0) {
                ///buscamos el precio mas alto de las ofertas
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
            //Tiene un costo variable pero mínimo de 500 MATE,
            if (price == 0) {
                price = 500 * 10 ** 18;
            } else {
                uint256 mateReward = Evvm(evvmAddress.current)
                    .seeMateReward();
                ///coloca el precio del username en un 0.5% del precio de la oferta más alta, con tope en 500,000 * mateReward
                price = ((price * 5) / 1000) > (500000 * mateReward)
                    ? (500000 * mateReward)
                    : ((price * 5) / 1000);
            }
        } else {
            price = 500_000 * Evvm(evvmAddress.current).seeMateReward();
        }
    }

    function getPriceToAddCustomMetadata() public view returns (uint256 price) {
        price = 10 * Evvm(evvmAddress.current).seeMateReward();
    }

    function getPriceToRemoveCustomMetadata()
        public
        view
        returns (uint256 price)
    {
        price = 10 * Evvm(evvmAddress.current).seeMateReward();
    }

    function getPriceToFlushCustomMetadata(
        string memory _identity
    ) public view returns (uint256 price) {
        price =
            (10 * Evvm(evvmAddress.current).seeMateReward()) *
            identityDetails[_identity].customMetadataMaxSlots;
    }

    function getPriceToFlushUsername(
        string memory _identity
    ) public view returns (uint256 price) {
        price =
            ((10 * Evvm(evvmAddress.current).seeMateReward()) *
                identityDetails[_identity].customMetadataMaxSlots) +
            Evvm(evvmAddress.current).seeMateReward();
    }

    //█User██████████████████████████████████████████████████████████████████████████████

    function checkIfMNSNonceIsAvailable(
        address _user,
        uint256 _nonce
    ) public view returns (bool) {
        return mateNameServiceNonce[_user][_nonce];
    }

    //█Identity (general)████████████████████████████████████████████████████████████████
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

    function getIdentityBasicMetadata(
        string memory _username
    ) public view returns (address, uint256) {
        return (
            identityDetails[_username].owner,
            identityDetails[_username].expireDate
        );
    }

    function getAmountOfCustomMetadata(
        string memory _username
    ) public view returns (uint256) {
        return identityDetails[_username].customMetadataMaxSlots;
    }

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

    function getSingleCustomMetadataOfIdentity(
        string memory _username,
        uint256 _key
    ) public view returns (string memory) {
        return identityCustomMetadata[_username][_key];
    }

    function getCustomMetadataMaxSlotsOfIdentity(
        string memory _username
    ) public view returns (uint256) {
        return identityDetails[_username].customMetadataMaxSlots;
    }

    //█Usernames█████████████████████████████████████████████████████████████████████████

    /**
     * @dev Returns offres has not been withdrawn (expired or unexpired)
     * @param _username The username to get the offers
     */
    function getOffersOfUsername(
        string memory _username
    ) public view returns (OfferMetadata[] memory offers) {
        offers = new OfferMetadata[](identityDetails[_username].offerMaxSlots);

        for (uint256 i = 0; i < identityDetails[_username].offerMaxSlots; i++) {
            offers[i] = usernameOffers[_username][i];
        }
    }

    function getSingleOfferOfUsername(
        string memory _username,
        uint256 _offerID
    ) public view returns (OfferMetadata memory offer) {
        return usernameOffers[_username][_offerID];
    }

    function getLengthOfOffersUsername(
        string memory _username
    ) public view returns (uint256 length) {
        do {
            length++;
        } while (usernameOffers[_username][length].expireDate != 0);
    }

    function getExpireDateOfIdentity(
        string memory _identity
    ) public view returns (uint256) {
        return identityDetails[_identity].expireDate;
    }

    function getPricePerRegistration() public view returns (uint256) {
        return Evvm(evvmAddress.current).seeMateReward() * 100;
    }

    function getAdmin() public view returns (address) {
        return admin.current;
    }

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

    function getEvvmAddress() public view returns (address) {
        return evvmAddress.current;
    }

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
