// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

import {SignatureUtil} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";

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
            SignatureUtil.verifySignature(
                evvmID,
                "makeOrder",
                string.concat(
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_amountA),
                    ",",
                    AdvancedStrings.uintToString(_amountB)
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
            SignatureUtil.verifySignature(
                evvmID,
                "cancelOrder",
                string.concat(
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_orderId)
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
            SignatureUtil.verifySignature(
                evvmID,
                "dispatchOrder",
                string.concat(
                    AdvancedStrings.uintToString(_nonce),
                    ",",
                    AdvancedStrings.addressToString(_tokenA),
                    ",",
                    AdvancedStrings.addressToString(_tokenB),
                    ",",
                    AdvancedStrings.uintToString(_orderId)
                ),
                signature,
                signer
            );
    }
}
