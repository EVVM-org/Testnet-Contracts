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


import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

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
            AdvancedStrings.uintToString(evvmID),
            ",",
            "pay",
            ",",
            _receiverAddress == address(0)
                ? _receiverIdentity
                : AdvancedStrings.addressToString(_receiverAddress),
            ",",
            AdvancedStrings.addressToString(_token),
            ",",
            AdvancedStrings.uintToString(_amount),
            ",",
            AdvancedStrings.uintToString(_priorityFee),
            ",",
            AdvancedStrings.uintToString(_nonce),
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "dispersePay",
                    ",",
                    AdvancedStrings.bytes32ToString(hashList),
                    ",",
                    AdvancedStrings.addressToString(_token),
                    ",",
                    AdvancedStrings.uintToString(_amount),
                    ",",
                    AdvancedStrings.uintToString(_priorityFee),
                    ",",
                    AdvancedStrings.uintToString(_nonce),
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "preRegistrationUsername",
                    ",",
                    AdvancedStrings.bytes32ToString(_hashUsername),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "registrationUsername",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_clowNumber),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "makeOffer",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_dateExpire),
                    ",",
                    AdvancedStrings.uintToString(_amount),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "withdrawOffer",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_offerId),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "acceptOffer",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_offerId),
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "renewUsername",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "addCustomMetadata",
                    ",",
                    _username,
                    ",",
                    _value,
                    ",",
                    AdvancedStrings.uintToString(_nameServiceNonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "removeCustomMetadata",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_key),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "flushCustomMetadata",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_nonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "flushUsername",
                    ",",
                    _username,
                    ",",
                    AdvancedStrings.uintToString(_nonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "publicServiceStaking",
                    ",",
                    AdvancedStrings.addressToString(_serviceAddress),
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    AdvancedStrings.uintToString(_amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "publicStaking",
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    AdvancedStrings.uintToString(_amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
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
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "presaleStaking",
                    ",",
                    _isStaking ? "true" : "false",
                    ",",
                    AdvancedStrings.uintToString(_amountOfStaking),
                    ",",
                    AdvancedStrings.uintToString(_nonce)
                )
            );
    }

    //-----------------------------------------------------------------------------------
    // P2PSwap functions
    //-----------------------------------------------------------------------------------

    function buildMessageSignedForMakeOrder(
        uint256 evvmID,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "makeOrder",
                    ",",
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_amountA),
                    ",",
                    AdvancedStrings.uintToString(_amountB)
                )
            );
    }

    function buildMessageSignedForCancelOrder(
        uint256 evvmID,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _orderId
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "cancelOrder",
                    ",",
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_orderId)
                )
            );
    }

    function buildMessageSignedForDispatchOrder(
        uint256 evvmID,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _orderId
    ) internal pure returns (bytes32 messageHash) {
        return
            buildHashForSign(
                string.concat(
                    AdvancedStrings.uintToString(evvmID),
                    ",",
                    "dispatchOrder",
                    ",",
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_orderId)
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
                    AdvancedStrings.uintToString(bytes(messageToSign).length),
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
