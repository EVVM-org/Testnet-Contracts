// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM function correct behavior
 * @notice some functions has evvm functions that are implemented
 *         for payment and dosent need to be tested here
 */

pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {NameServiceStructs} from "@evvm/testnet-contracts/contracts/nameService/lib/NameServiceStructs.sol";
import {NameService} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Erc191TestBuilder} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {EvvmStorage} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_EVVM_dispersePay is Test, Constants, EvvmStructs {

    
    
    
    

    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_2,
            "dummy",
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2)
        );
    }

    function addBalance(
        address user,
        address token,
        uint256 amount,
        uint256 priorityFee
    ) private {
        evvm.addBalance(user, token, amount + priorityFee);
    }

    

    /**
     * Function to test: dispersePay

     * PF: Includes priority fee
     * nPF: No priority fee

     */

    struct DispersePayFuzzTestInput_nPF {
        bool useToAddress;
        bool useExecutor;
        bool useStaker;
        address token;
        uint16 amountA;
        uint16 amountB;
        uint176 nonce;
        bool priorityFlag;
    }

    struct DispersePayFuzzTestInput_PF {
        bool useToAddress;
        bool useExecutor;
        bool useStaker;
        address token;
        uint16 amountA;
        uint16 amountB;
        uint16 priorityFee;
        uint176 nonce;
        bool priorityFlag;
    }

    function test__fuzz__dispersePay__nPF(
        DispersePayFuzzTestInput_nPF memory input
    ) external {
        vm.assume(
            input.amountA > 0 &&
                input.amountB > 0 &&
                input.token != MATE_TOKEN_ADDRESS
        );

        uint256 totalAmount = uint256(input.amountA) + uint256(input.amountB);

        AccountData memory selectedExecuter = input.useStaker
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_3;

        uint256 nonce = input.priorityFlag
            ? input.nonce
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            input.token,
            totalAmount,
            0
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: input.amountA,
            to_address: COMMON_USER_NO_STAKER_3.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: input.amountB,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signatureEVVM = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            input.token,
            totalAmount,
            0,
            nonce,
            input.priorityFlag,
            input.useExecutor ? selectedExecuter.Address : address(0)
        );

        vm.startPrank(selectedExecuter.Address);

        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            input.token,
            totalAmount,
            0,
            nonce,
            input.priorityFlag,
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
            input.amountB
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_3.Address, input.token),
            input.amountA
        );

        if (selectedExecuter.Address == COMMON_USER_STAKER.Address) {
            assertEq(
                evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
                evvm.getRewardAmount()
            );
        }
    }

    function test__fuzz__dispersePay__PF(
        DispersePayFuzzTestInput_PF memory input
    ) external {
        vm.assume(
            input.amountA > 0 &&
                input.amountB > 0 &&
                input.priorityFee > 0 &&
                input.token != MATE_TOKEN_ADDRESS
        );

        uint256 totalAmount = uint256(input.amountA) + uint256(input.amountB);

        AccountData memory selectedExecuter = input.useStaker
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_3;

        uint256 nonce = input.priorityFlag
            ? input.nonce
            : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            input.token,
            totalAmount,
            input.priorityFee
        );

        EvvmStructs.DispersePayMetadata[]
            memory toData = new EvvmStructs.DispersePayMetadata[](2);

        toData[0] = EvvmStructs.DispersePayMetadata({
            amount: input.amountA,
            to_address: COMMON_USER_NO_STAKER_3.Address,
            to_identity: ""
        });

        toData[1] = EvvmStructs.DispersePayMetadata({
            amount: input.amountB,
            to_address: address(0),
            to_identity: "dummy"
        });

        bytes memory signatureEVVM = _execute_makeDispersePaySignature(
            COMMON_USER_NO_STAKER_1,
            toData,
            input.token,
            totalAmount,
            input.priorityFee,
            nonce,
            input.priorityFlag,
            input.useExecutor ? selectedExecuter.Address : address(0)
        );

        vm.startPrank(selectedExecuter.Address);

        evvm.dispersePay(
            COMMON_USER_NO_STAKER_1.Address,
            toData,
            input.token,
            totalAmount,
            input.priorityFee,
            nonce,
            input.priorityFlag,
            input.useExecutor ? selectedExecuter.Address : address(0),
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, input.token),
            (input.useStaker ? 0 : input.priorityFee)
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_3.Address, input.token),
            input.amountA
        );

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_2.Address, input.token),
            input.amountB
        );

        if (selectedExecuter.Address == COMMON_USER_STAKER.Address) {
            assertEq(
                evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
                evvm.getRewardAmount()
            );

            assertEq(
                evvm.getBalance(COMMON_USER_STAKER.Address, input.token),
                input.priorityFee
            );
        }
    }
}
