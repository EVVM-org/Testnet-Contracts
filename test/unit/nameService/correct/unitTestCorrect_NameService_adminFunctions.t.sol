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
import {NameService} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Erc191TestBuilder} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {EvvmStorage} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestCorrect_NameService_adminFunctions is Test, Constants {
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
    }

    function test__unit_correct__proposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(current, ADMIN.Address);
        assertEq(proposal, WILDCARD_USER.Address);
        assertEq(timeToAccept, block.timestamp + 1 days);
    }

    function test__unit_correct__cancelProposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        nameService.cancelProposeAdmin();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(current, ADMIN.Address);
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }

    function test__unit_correct__acceptProposeAdmin() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeAdmin(WILDCARD_USER.Address);
        vm.stopPrank();

        skip(1 days);

        vm.startPrank(WILDCARD_USER.Address);
        nameService.acceptProposeAdmin();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getAdminFullDetails();

        assertEq(current, WILDCARD_USER.Address);
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }

    function test__unit_correct__proposeWithdrawPrincipalTokens() external {
        uint256 totalInEvvm = evvm.getBalance(
            address(nameService),
            MATE_TOKEN_ADDRESS
        );
        uint256 removeAmount = totalInEvvm / 10;

        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(removeAmount);
        vm.stopPrank();

        (uint256 amount, uint256 time) = nameService
            .getProposedWithdrawAmountFullDetails();

        assertEq(amount, removeAmount);
        assertEq(time, block.timestamp + 1 days);
    }

    function test__unit_correct__cancelWithdrawPrincipalTokenss() external {
        uint256 totalInEvvm = evvm.getBalance(
            address(nameService),
            MATE_TOKEN_ADDRESS
        );
        uint256 removeAmount = totalInEvvm / 10;

        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(removeAmount);
        nameService.cancelWithdrawPrincipalTokens();
        vm.stopPrank();

        (uint256 amount, uint256 time) = nameService
            .getProposedWithdrawAmountFullDetails();

        assertEq(amount, 0);
        assertEq(time, 0);
    }

    function test__unit_correct__claimWithdrawPrincipalTokens() external {
        uint256 totalInEvvm = evvm.getBalance(
            address(nameService),
            MATE_TOKEN_ADDRESS
        );
        uint256 removeAmount = totalInEvvm / 10;

        vm.startPrank(ADMIN.Address);
        nameService.proposeWithdrawPrincipalTokens(removeAmount);
        skip(1 days);
        nameService.claimWithdrawPrincipalTokens();
        vm.stopPrank();

        assertEq(
            evvm.getBalance(address(nameService), MATE_TOKEN_ADDRESS),
            (totalInEvvm - removeAmount) + evvm.getRewardAmount()
        );

        (uint256 amount, uint256 time) = nameService
            .getProposedWithdrawAmountFullDetails();

        assertEq(amount, 0);
        assertEq(time, 0);
    }

    function test__unit_correct__proposeChangeEvvmAddress() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(current, address(evvm));
        assertEq(proposal, WILDCARD_USER.Address);
        assertEq(timeToAccept, block.timestamp + 1 days);
    }

    function test__unit_correct__cancelChangeEvvmAddress() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        nameService.cancelChangeEvvmAddress();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(current, address(evvm));
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }

    function test__unit_correct__acceptChangeEvvmAddress() external {
        vm.startPrank(ADMIN.Address);
        nameService.proposeChangeEvvmAddress(WILDCARD_USER.Address);
        skip(1 days);
        nameService.acceptChangeEvvmAddress();
        vm.stopPrank();

        (address current, address proposal, uint256 timeToAccept) = nameService
            .getEvvmAddressFullDetails();

        assertEq(current, WILDCARD_USER.Address);
        assertEq(proposal, address(0));
        assertEq(timeToAccept, 0);
    }

}
