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
import {
    NameServiceStructs
} from "@evvm/testnet-contracts/contracts/nameService/lib/NameServiceStructs.sol";
import {
    NameService
} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    Erc191TestBuilder
} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {
    Estimator
} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {
    EvvmStorage
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_EVVM_pay_staker_sync is Test, Constants {
    AccountData COMMON_USER_STAKER_1 = COMMON_USER_STAKER;
    AccountData COMMON_USER_STAKER_2 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER_1.Address, 0x01);
        evvm.setPointStaker(COMMON_USER_STAKER_2.Address, 0x01);

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_2,
            "dummy",
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1
            ),
            uint256(
                0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2
            )
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

    /**
     * Function to test: payNoStaker_sync
     * PF: Includes priority fee
     * nPF: No priority fee
     * EX: Includes executor execution
     * nEX: Does not include executor execution
     * ID: Uses a NameService identity
     * AD: Uses an address
     */

    struct PayStakerSyncFuzzTestInput_nPF {
        bool useToAddress;
        bool useExecutor;
        bool useNoStaker3;
        address token;
        uint16 amount;
    }

    struct PayStakerSyncFuzzTestInput_PF {
        bool useToAddress;
        bool useExecutor;
        bool useNoStaker3;
        address token;
        uint16 amount;
        uint16 priorityFee;
    }

    function test__fuzz__pay_staker_sync__nPF(
        PayStakerSyncFuzzTestInput_nPF memory input
    ) external {
        vm.assume(input.amount > 0);

        AccountData memory selectedExecuter = input.useNoStaker3
            ? COMMON_USER_STAKER_1
            : COMMON_USER_STAKER_2;

        (uint256 totalAmount, uint256 totalPriorityFee) = addBalance(
            COMMON_USER_NO_STAKER_1,
            input.token,
            input.amount,
            0
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                input.useToAddress
                    ? COMMON_USER_NO_STAKER_2.Address
                    : address(0),
                input.useToAddress ? "" : "dummy",
                input.token,
                totalAmount,
                totalPriorityFee,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false,
                input.useExecutor ? selectedExecuter.Address : address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(selectedExecuter.Address);

        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            input.useToAddress ? COMMON_USER_NO_STAKER_2.Address : address(0),
            input.useToAddress ? "" : "dummy",
            input.token,
            totalAmount,
            totalPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            input.useExecutor ? selectedExecuter.Address : address(0),
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            0
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, input.token),
            totalAmount
        );

        if (input.token == PRINCIPAL_TOKEN_ADDRESS) {
            assertEq(
                evvm.getBalance(selectedExecuter.Address, PRINCIPAL_TOKEN_ADDRESS),
                evvm.getRewardAmount() + totalPriorityFee
            );
        } else {
            assertEq(
                evvm.getBalance(selectedExecuter.Address, input.token),
                totalPriorityFee
            );
            assertEq(
                evvm.getBalance(selectedExecuter.Address, PRINCIPAL_TOKEN_ADDRESS),
                evvm.getRewardAmount()
            );
        }
    }

    function test__fuzz__pay_staker_sync__PF(
        PayStakerSyncFuzzTestInput_PF memory input
    ) external {
        vm.assume(input.amount > 0);

        AccountData memory selectedExecuter = input.useNoStaker3
            ? COMMON_USER_STAKER_1
            : COMMON_USER_STAKER_2;

        (uint256 totalAmount, uint256 totalPriorityFee) = addBalance(
            COMMON_USER_NO_STAKER_1,
            input.token,
            input.amount,
            input.priorityFee
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                input.useToAddress
                    ? COMMON_USER_NO_STAKER_2.Address
                    : address(0),
                input.useToAddress ? "" : "dummy",
                input.token,
                totalAmount,
                totalPriorityFee,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false,
                input.useExecutor ? selectedExecuter.Address : address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(selectedExecuter.Address);

        evvm.pay(
            COMMON_USER_NO_STAKER_1.Address,
            input.useToAddress ? COMMON_USER_NO_STAKER_2.Address : address(0),
            input.useToAddress ? "" : "dummy",
            input.token,
            totalAmount,
            totalPriorityFee,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            input.useExecutor ? selectedExecuter.Address : address(0),
            signatureEVVM
        );
        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            0
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, input.token),
            totalAmount
        );

        if (input.token == PRINCIPAL_TOKEN_ADDRESS) {
            assertEq(
                evvm.getBalance(selectedExecuter.Address, PRINCIPAL_TOKEN_ADDRESS),
                evvm.getRewardAmount() + totalPriorityFee
            );
        } else {
            assertEq(
                evvm.getBalance(selectedExecuter.Address, input.token),
                totalPriorityFee
            );
            assertEq(
                evvm.getBalance(selectedExecuter.Address, PRINCIPAL_TOKEN_ADDRESS),
                evvm.getRewardAmount()
            );
        }
    }
}
