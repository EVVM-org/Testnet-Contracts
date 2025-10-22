// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface INameService {
    struct OfferMetadata {
        address offerer;
        uint256 expireDate;
        uint256 amount;
    }

    error AcceptOfferVerificationFailed();
    error EmptyCustomMetadata();
    error FlushUsernameVerificationFailed();
    error InvalidKey();
    error InvalidSignatureOnNameService();
    error InvalidUsername(bytes1);
    error NonceAlreadyUsed();
    error PreRegistrationNotValid();
    error RenewUsernameVerificationFailed();
    error SenderIsNotAdmin();
    error UserIsNotOwnerOfIdentity();
    error UserIsNotOwnerOfOffer();
    error UsernameAlreadyRegistered();

    function acceptChangeEvvmAddress() external;

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
    ) external;

    function acceptProposeAdmin() external;

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
    ) external;

    function cancelChangeEvvmAddress() external;

    function cancelProposeAdmin() external;

    function cancelWithdrawPrincipalTokens() external;

    function checkIfNameServiceNonceIsAvailable(
        address _user,
        uint256 _nonce
    ) external view returns (bool);

    function claimWithdrawPrincipalTokens() external;

    function flushCustomMetadata(
        address user,
        string memory identity,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external;

    function flushUsername(
        address user,
        string memory username,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external;

    function getAdmin() external view returns (address);

    function getAdminFullDetails()
        external
        view
        returns (
            address currentAdmin,
            address proposalAdmin,
            uint256 timeToAcceptAdmin
        );

    function getAmountOfCustomMetadata(
        string memory _username
    ) external view returns (uint256);

    function getCustomMetadataMaxSlotsOfIdentity(
        string memory _username
    ) external view returns (uint256);

    function getEvvmAddress() external view returns (address);

    function getEvvmAddressFullDetails()
        external
        view
        returns (
            address currentEvvmAddress,
            address proposalEvvmAddress,
            uint256 timeToAcceptEvvmAddress
        );

    function getExpireDateOfIdentity(
        string memory _identity
    ) external view returns (uint256);

    function getFullCustomMetadataOfIdentity(
        string memory _username
    ) external view returns (string[] memory);

    function getIdentityBasicMetadata(
        string memory _username
    ) external view returns (address, uint256);

    function getLengthOfOffersUsername(
        string memory _username
    ) external view returns (uint256 length);

    function getOffersOfUsername(
        string memory _username
    ) external view returns (OfferMetadata[] memory offers);

    function getOwnerOfIdentity(
        string memory _username
    ) external view returns (address);

    function getPricePerRegistration() external view returns (uint256);

    function getPriceToAddCustomMetadata()
        external
        view
        returns (uint256 price);

    function getPriceToFlushCustomMetadata(
        string memory _identity
    ) external view returns (uint256 price);

    function getPriceToFlushUsername(
        string memory _identity
    ) external view returns (uint256 price);

    function getPriceToRemoveCustomMetadata()
        external
        view
        returns (uint256 price);

    function getProposedWithdrawAmountFullDetails()
        external
        view
        returns (
            uint256 proposalAmountToWithdrawTokens,
            uint256 timeToAcceptAmountToWithdrawTokens
        );

    function getSingleCustomMetadataOfIdentity(
        string memory _username,
        uint256 _key
    ) external view returns (string memory);

    function getSingleOfferOfUsername(
        string memory _username,
        uint256 _offerID
    ) external view returns (OfferMetadata memory offer);

    function hashUsername(
        string memory _username,
        uint256 _randomNumber
    ) external pure returns (bytes32);

    function isUsernameAvailable(
        string memory _username
    ) external view returns (bool);

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
    ) external returns (uint256 offerID);

    function preRegistrationUsername(
        address user,
        bytes32 hashPreRegisteredUsername,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external;

    function proposeAdmin(address _adminToPropose) external;

    function proposeChangeEvvmAddress(address _newEvvmAddress) external;

    function proposeWithdrawPrincipalTokens(uint256 _amount) external;

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
    ) external;

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
    ) external;

    function renewUsername(
        address user,
        string memory username,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external;

    function seePriceToRenew(
        string memory _identity
    ) external view returns (uint256 price);

    function strictVerifyIfIdentityExist(
        string memory _username
    ) external view returns (bool);

    function verifyIfIdentityExists(
        string memory _identity
    ) external view returns (bool);

    function verifyStrictAndGetOwnerOfIdentity(
        string memory _username
    ) external view returns (address answer);

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
    ) external;
}
