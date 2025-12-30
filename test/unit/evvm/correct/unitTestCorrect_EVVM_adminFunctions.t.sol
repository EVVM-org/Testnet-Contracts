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

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
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

contract unitTestCorrect_EVVM_adminFunctions is Test, Constants {


    /**
     * Function to test: payNoStaker_sync
     * PF: Includes priority fee
     * nPF: No priority fee
     * EX: Includes executor execution
     * nEX: Does not include executor execution
     * ID: Uses a NameService identity
     * AD: Uses an address
     */

    function test__unit_correct__set_owner() external {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.stopPrank();

        vm.warp(block.timestamp + 1 days + 1 hours);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        evvm.acceptAdmin();

        vm.stopPrank();

        assertEq(evvm.getCurrentAdmin(), COMMON_USER_NO_STAKER_1.Address);
    }

    function test__unit_correct__cancel_set_owner() external {
        vm.startPrank(ADMIN.Address);

        evvm.proposeAdmin(COMMON_USER_NO_STAKER_1.Address);

        vm.warp(block.timestamp + 10 hours);

        evvm.rejectProposalAdmin();

        vm.stopPrank();

        assertEq(evvm.getCurrentAdmin(), ADMIN.Address);
    }

    //_addMateToTotalSupply getEraPrincipalToken

    function test__unit_correct__setEvvmID() external {
        vm.startPrank(ADMIN.Address);

        evvm.setEvvmID(888);

        assertEq(evvm.getEvvmID(), 888);

        skip(23 hours);

        evvm.setEvvmID(777);

        vm.stopPrank();

        assertEq(evvm.getEvvmID(), 777);
    }
}
