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


    function verifyMessageSignedForFisherBridge(
        uint256 evvmID,
        address signer,
        address addressToReceive,
        uint256 nonce,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) internal pure returns (bool) {
        return
            SignatureRecover.signatureVerification(
                Strings.toString(evvmID),
                "fisherBridge",
                string.concat(
                    AdvancedStrings.addressToString(addressToReceive),
                    ",",
                    Strings.toString(nonce),
                    ",",
                    AdvancedStrings.addressToString(tokenAddress),
                    ",",
                    Strings.toString(priorityFee),
                    ",",
                    Strings.toString(amount)
                ),
                signature,
                signer
            );
    }
}
