// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

import {SignatureRecover} from "@evvm/testnet-contracts/library/SignatureRecover.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/AdvancedStrings.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.0;

library SignatureUtils {
    /**
     *  @dev using EIP-191 (https://eips.ethereum.org/EIPS/eip-191) can be used to sign and
     *       verify messages, the next functions are used to verify the messages signed
     *       by the users
     */

    /**
     *  @notice This function is used to verify the message signed for the payment
     *  @param signer user who signed the message
     *  @param _receiverAddress address of the receiver
     *  @param _receiverIdentity identity of the receiver
     *
     *  @notice if the _receiverAddress is 0x0 the function will use the _receiverIdentity
     *
     *  @param _token address of the token to send
     *  @param _amount amount to send
     *  @param _priorityFee priorityFee to send to the staking holder
     *  @param _nonce nonce of the transaction
     *  @param _priorityFlag if the transaction is priority or not
     *  @param _executor the executor of the transaction
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
     */
    function verifyMessageSignedForPay(
        uint256 evvmID,
        address signer,
        address _receiverAddress,
        string memory _receiverIdentity,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priorityFlag,
        address _executor,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                Strings.toString(evvmID),
                "pay",
                string.concat(
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
                    _priorityFlag ? "true" : "false",
                    ",",
                    AdvancedStrings.addressToString(_executor)
                ),
                signature,
                signer
            );
    }

    /**
     *  @notice This function is used to verify the message signed for the dispersePay
     *  @param signer user who signed the message
     *  @param hashList hash of the list of the transactions, the hash is calculated
     *                  using sha256(abi.encode(toData))
     *  @param _token token address to send
     *  @param _amount amount to send
     *  @param _priorityFee priorityFee to send to the fisher who wants to send the message
     *  @param _nonce nonce of the transaction
     *  @param _priorityFlag if the transaction is priority or not
     *  @param _executor the executor of the transaction
     *  @param signature signature of the user who wants to send the message
     *  @return true if the signature is valid
     */
    function verifyMessageSignedForDispersePay(
        uint256 evvmID,
        address signer,
        bytes32 hashList,
        address _token,
        uint256 _amount,
        uint256 _priorityFee,
        uint256 _nonce,
        bool _priorityFlag,
        address _executor,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                Strings.toString(evvmID),
                "dispersePay",
                string.concat(
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
                    _priorityFlag ? "true" : "false",
                    ",",
                    AdvancedStrings.addressToString(_executor)
                ),
                signature,
                signer
            );
    }

}