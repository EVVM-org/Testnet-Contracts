// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**

:::::::::: :::    ::: ::::::::: :::::::::      ::::::::::: :::::::::: :::::::: ::::::::::: 
:+:        :+:    :+:      :+:       :+:           :+:     :+:       :+:    :+:    :+:     
+:+        +:+    +:+     +:+       +:+            +:+     +:+       +:+           +:+     
:#::+::#   +#+    +:+    +#+       +#+             +#+     +#++:++#  +#++:++#++    +#+     
+#+        +#+    +#+   +#+       +#+              +#+     +#+              +#+    +#+     
#+#        #+#    #+#  #+#       #+#               #+#     #+#       #+#    #+#    #+#     
###         ########  ######### #########          ###     ########## ########     ###     

 * @title unit test for EVVM function correct behavior
 * @notice some functions has evvm functions that are implemented
 *         for payment and dosent need to be tested here
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {NameService} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {NameServiceStructs} from "@evvm/testnet-contracts/contracts/nameService/lib/NameServiceStructs.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Erc191TestBuilder} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {EvvmStorage} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_EVVM_batchPay is Test, Constants, EvvmStructs {
    Staking staking;
    Evvm evvm;
    Estimator estimator;
    NameService nameService;
    Treasury treasury;

    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function setUp() public {
        staking = new Staking(ADMIN.Address, GOLDEN_STAKER.Address);
        evvm = new Evvm(
            ADMIN.Address,
            address(staking),
            EvvmStructs.EvvmMetadata({
                EvvmName: "EVVM",
                EvvmID: 777,
                principalTokenName: "EVVM Staking Token",
                principalTokenSymbol: "EVVM-STK",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 2033333333000000000000000000 / 2,
                reward: 5000000000000000000
            })
        );
        estimator = new Estimator(
            ACTIVATOR.Address,
            address(evvm),
            address(staking),
            ADMIN.Address
        );
        nameService = new NameService(address(evvm), ADMIN.Address);

        staking._setupEstimatorAndEvvm(address(estimator), address(evvm));
        treasury = new Treasury(address(evvm));
        evvm._setupNameServiceAndTreasuryAddress(address(nameService), address(treasury));

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
        nameService._setIdentityBaseMetadata(
            "dummy",
            NameServiceStructs.IdentityBaseMetadata({
                owner: COMMON_USER_NO_STAKER_2.Address,
                expireDate: block.timestamp + 366 days,
                customMetadataMaxSlots: 0,
                offerMaxSlots: 0,
                flagNotAUsername: 0x00
            })
        );
    }

    function addBalance(
        AccountData memory user,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee
    ) private returns (uint256 totalAmount, uint256 totalPriorityFee) {
        evvm.addBalance(user.Address, tokenAddress, amount + priorityFee);

        totalAmount = amount;
        totalPriorityFee = priorityFee;
    }

    function makeSignaturePay(
        AccountData memory user,
        address toAddress,
        string memory toIdentity,
        address tokenAddress,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        address executor
    ) private view returns (bytes memory signatureEVVM) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                toAddress,
                toIdentity,
                tokenAddress,
                amount,
                priorityFee,
                nonce,
                priorityFlag,
                executor
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    /**
     * Function to test: payNoStaker_sync
     * PF: Includes priority fee
     * nPF: No priority fee
     * EX: Includes executor execution
     * nEX: Does not include executor execution
     * ID: Uses a NameService identity
     * AD: Uses an address
     */

    struct PayMultipleFuzzTestInput {
        bool useStaker;
        bool[2] useToAddress;
        bool[2] useExecutor;
        address[2] token;
        uint16[2] amount;
        uint16[2] priorityFee;
        uint176[2] nonce;
        bool[2] priorityFlag;
    }

    function test__fuzz__batchPay__nonStaker(
        PayMultipleFuzzTestInput memory input
    ) external {
        vm.assume(
            input.amount[0] > 0 &&
                input.amount[1] > 0 &&
                input.token[0] != input.token[1] &&
                input.token[0] != MATE_TOKEN_ADDRESS &&
                input.token[1] != MATE_TOKEN_ADDRESS
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](2);

        AccountData memory FISHER = input.useStaker
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_3;

        bytes[3] memory signature;

        signature[0] = makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            input.useToAddress[0]
                ? COMMON_USER_NO_STAKER_2.Address
                : address(0),
            input.useToAddress[0] ? "" : "dummy",
            input.token[0],
            input.amount[0],
            input.priorityFee[0],
            input.priorityFlag[0]
                ? input.nonce[0]
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            input.priorityFlag[0],
            input.useExecutor[0] ? FISHER.Address : address(0)
        );

        signature[1] = makeSignaturePay(
            COMMON_USER_NO_STAKER_1,
            input.useToAddress[1]
                ? COMMON_USER_NO_STAKER_2.Address
                : address(0),
            input.useToAddress[1] ? "" : "dummy",
            input.token[1],
            input.amount[1],
            input.priorityFee[1],
            input.priorityFlag[1]
                ? input.nonce[1]
                : (
                    input.priorityFlag[0] == false
                        ? evvm.getNextCurrentSyncNonce(
                            COMMON_USER_NO_STAKER_1.Address
                        ) + 1
                        : evvm.getNextCurrentSyncNonce(
                            COMMON_USER_NO_STAKER_1.Address
                        )
                ),
            input.priorityFlag[1],
            input.useExecutor[1] ? FISHER.Address : address(0)
        );

        for (uint256 i = 0; i < 2; i++) {
            addBalance(
                COMMON_USER_NO_STAKER_1,
                input.token[i],
                input.amount[i],
                input.priorityFee[i]
            );

            payData[i] = EvvmStructs.PayData({
                from: COMMON_USER_NO_STAKER_1.Address,
                to_address: input.useToAddress[i]
                    ? COMMON_USER_NO_STAKER_2.Address
                    : address(0),
                to_identity: input.useToAddress[i] ? "" : "dummy",
                token: input.token[i],
                amount: input.amount[i],
                priorityFee: input.priorityFee[i],
                nonce: input.priorityFlag[i]
                    ? input.nonce[i]
                    : (
                        input.priorityFlag[0] == false && i == 1
                            ? evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            ) + 1
                            : evvm.getNextCurrentSyncNonce(
                                COMMON_USER_NO_STAKER_1.Address
                            )
                    ),
                priorityFlag: input.priorityFlag[i],
                executor: input.useExecutor[i] ? FISHER.Address : address(0),
                signature: signature[i]
            });
        }

        vm.startPrank(FISHER.Address);
        (
            uint256 successfulTransactions,
            bool[] memory status
        ) = evvm.batchPay(payData);
        vm.stopPrank();

        assertEq(successfulTransactions, 2);
        assertEq(status[0], true);
        assertEq(status[1], true);

        for (uint256 i = 0; i < 2; i++) {
            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_2.Address,
                    input.token[i]
                ),
                input.amount[i]
            );
        }

        if (FISHER.Address == COMMON_USER_STAKER.Address) {
            for (uint256 i = 0; i < 2; i++) {
                assertEq(
                    evvm.getBalance(COMMON_USER_STAKER.Address, input.token[i]),
                    input.priorityFee[i]
                );
            }

            assertEq(
                evvm.getBalance(FISHER.Address, MATE_TOKEN_ADDRESS),
                evvm.getRewardAmount() * 2
            );
        } else {
            for (uint256 i = 0; i < 2; i++) {
                assertEq(
                    evvm.getBalance(
                        COMMON_USER_NO_STAKER_1.Address,
                        input.token[i]
                    ),
                    input.priorityFee[i]
                );
            }

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_3.Address,
                    MATE_TOKEN_ADDRESS
                ),
                0
            );
        }

        for (uint256 i = 0; i < 2; i++) {
            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_2.Address,
                    input.token[i]
                ),
                input.amount[i]
            );
        }
    }
}
