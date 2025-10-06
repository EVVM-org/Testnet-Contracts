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
        address _receiverAddress,
        string memory _receiverIdentity,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priority_boolean,
        address _executor
    ) internal pure returns (bytes32 messageHash) {
        string memory messageToSign = _receiverAddress == address(0)
            ? string.concat(
                _priority_boolean ? "f4e1895b" : "4faa1fa2",
                ",",
                _receiverIdentity,
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
            : string.concat(
                _priority_boolean ? "f4e1895b" : "4faa1fa2",
                ",",
                AdvancedStrings.addressToString(_receiverAddress),
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
                    "ef83c1d6",
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
        bytes32 _hashUsername,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "5d232a55",
                    ",",
                    AdvancedStrings.bytes32ToString(_hashUsername),
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForRegistrationUsername(
        string memory _username,
        uint256 _clowNumber,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "afabc8db",
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
        string memory _username,
        uint256 _dateExpire,
        uint256 _amount,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "d82e5d8b",
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
        string memory _username,
        uint256 _offerId,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "5761d8ed",
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
        string memory _username,
        uint256 _offerId,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "8e3bde43", //methodIdentifier
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
        string memory _username,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "35723e23",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_nameServiceNonce)
                )
            );
    }

    function buildMessageSignedForAddCustomMetadata(
        string memory _username,
        string memory _value,
        uint256 _nameServiceNonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "4cfe021f",
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
        string memory _username,
        uint256 _key,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "8adf3927",
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
        string memory _username,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "3ca44e54",
                    ",",
                    _username,
                    ",",
                    Strings.toString(_nonce)
                )
            );
    }

    function buildMessageSignedForFlushUsername(
        string memory _username,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "044695cb",
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
        address _serviceAddress,
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "e2ccd470",
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
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "c769095c",
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
        bool _isStaking,
        uint256 _amountOfStaking,
        uint256 _nonce
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    "c0f6e7d1",
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
