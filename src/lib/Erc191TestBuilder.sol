// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 * @title Erc191TestBuilder
 * @author jistro.eth
 * @notice this library is used to build ERC191 messages for foundry test scripts
 *         more info in
 *         https://book.getfoundry.sh/cheatcodes/create-wallet
 *         https://book.getfoundry.sh/cheatcodes/sign
 */

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {AdvancedStrings} from "./AdvancedStrings.sol";

library Erc191TestBuilder {
    //-----------------------------------------------------------------------------------
    // EVVM
    //-----------------------------------------------------------------------------------
    function buildMessageSignedForPay(
        uint256 evvmID,
        address _receiverAddress,
        string memory _receiverIdentity,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priority_boolean,
        address _executor
    ) internal pure returns (bytes32 messageHash) {
        string memory messageToSign = string.concat(
            Strings.toString(evvmID),
            ",",
            "pay",
            ",",
            _receiverAddress == address(0)
                ? _receiverIdentity
                : AdvancedStrings.addressToString(_receiverAddress),
            ",",
            AdvancedStrings.addressToString(_token),
            ",",
            Strings.toString(_amount),
            ",",
            Strings.toString(_priorityFee),
            ",",
            Strings.toString(_nonce),
            ",",
            _priority_boolean ? "true" : "false",
            ",",
            AdvancedStrings.addressToString(_executor)
        );
        messageHash = buildHashForSign(messageToSign);
    }

    function buildMessageSignedForDispersePay(
        uint256 evvmID,
        bytes32 hashList,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priority_boolean,
        address _executor
    ) public pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "dispersePay",
                    ",",
                    AdvancedStrings.bytes32ToString(hashList),
                    ",",
                    AdvancedStrings.addressToString(_token),
                    ",",
                    Strings.toString(_amount),
                    ",",
                    Strings.toString(_priorityFee),
                    ",",
                    Strings.toString(_nonce),
                    ",",
                    _priority_boolean ? "true" : "false",
                    ",",
                    AdvancedStrings.addressToString(_executor)
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // MATE NAME SERVICE
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForPreRegistrationUsername(
        uint256 evvmID,
        bytes32 _hashUsername,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "preRegistrationUsername",
                    ",",
                    AdvancedStrings.bytes32ToString(_hashUsername),
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForRegistrationUsername(
        uint256 evvmID,
        string memory _username,
        uint256 _clowNumber,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "registrationUsername",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_clowNumber),
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForMakeOffer(
        uint256 evvmID,
        string memory _username,
        uint256 _dateExpire,
        uint256 _amount,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "makeOffer",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_dateExpire),
                    ",",
                    Strings.toString(_amount),
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForWithdrawOffer(
        uint256 evvmID,
        string memory _username,
        uint256 _offerId,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "withdrawOffer",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_offerId),
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForAcceptOffer(
        uint256 evvmID,
        string memory _username,
        uint256 _offerId,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "acceptOffer", 
                    ",",
                    _username,
                    ",",
                    Strings.toString(_offerId),
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForRenewUsername(
        uint256 evvmID,
        string memory _username,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "renewUsername",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForAddCustomMetadata(
        uint256 evvmID,
        string memory _username,
        string memory _value,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "addCustomMetadata",
                    ",",
                    _username,
                    ",",
                    _value,
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForRemoveCustomMetadata(
        uint256 evvmID,
        string memory _username,
        uint256 _key,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "removeCustomMetadata",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_key),
                    ",",
                    Strings.toString(_nonce)
                )
            );
    }

    function buildMessageSignedForFlushCustomMetadata(
        uint256 evvmID,
        string memory _username,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "flushCustomMetadata",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_nonce)
                )
            );
    }

    function buildMessageSignedForFlushUsername(
        uint256 evvmID,
        string memory _username,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "flushUsername",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_nonce)
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // staking functions
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForPublicServiceStake(
        uint256 evvmID,
        address _serviceAddress,
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "publicServiceStaking",
                    ",",
                    AdvancedStrings.addressToString(_serviceAddress),
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    Strings.toString(_amountOfStaking),
                    ",",
                    Strings.toString(_nonce)
                )
            );
    }

    function buildMessageSignedForPublicStaking(
        uint256 evvmID,
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "publicStaking",
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    Strings.toString(_amountOfStaking),
                    ",",
                    Strings.toString(_nonce)
                )
            );
    }

    function buildMessageSignedForPresaleStaking(
        uint256 evvmID,
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    Strings.toString(evvmID),
                    ",",
                    "presaleStaking",
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    Strings.toString(_amountOfStaking),
                    ",",
                    Strings.toString(_nonce)
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // General functions
    //-----------------------------------------------------------------------------------

    function buildHashForSign(
        string memory messageToSign
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n",
                    Strings.toString(bytes(messageToSign).length),
                    messageToSign
                )
            );
    }

    function buildERC191Signature(
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, bytes1(v));
    }
}
