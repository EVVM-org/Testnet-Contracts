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

    function verifyMessageSignedForMakeOrder(
        uint256 evvmID,
        address signer,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                Strings.toString(evvmID),
                "makeOrder",
                string.concat(
                    Strings.toString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    Strings.toString(_amountA),
                    ",",
                    Strings.toString(_amountB)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForCancelOrder(
        uint256 evvmID,
        address signer,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _orderId,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                Strings.toString(evvmID),
                "cancelOrder",
                string.concat(
                    Strings.toString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    Strings.toString(_orderId)
                ),
                signature,
                signer
            );
    }

    function verifyMessageSignedForDispatchOrder(
        uint256 evvmID,
        address signer,
        uint256 _nonce,
        address _tokenA,
        address _tokenB,
        uint256 _orderId,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                Strings.toString(evvmID),
                "dispatchOrder",
                string.concat(
                    Strings.toString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    Strings.toString(_orderId)
                ),
                signature,
                signer
            );
    }
}
