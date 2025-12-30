// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM function revert behavior
 * @notice some functions has evvm functions that are implemented
 *         and dosent need to be tested here
 */
pragma solidity ^0.8.0;
pragma abicoder v2;

import "forge-std/Test.sol";
import "forge-std/console2.sol";

import {Constants} from "test/Constants.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

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
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestRevert_EVVM_disperseCaPay is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
    }

    function addBalance(address user, address token, uint256 amount) private {
        evvm.addBalance(user, token, amount);
    }

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     */

    function test__unit_revert__disperseCaPay__addressHasZeroOpcode() external {
        addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, 0.02 ether);

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.01 ether,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        toData[1] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.01 ether,
            toAddress: COMMON_USER_NO_STAKER_3.Address
        });

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert();
        evvm.disperseCaPay(toData, ETHER_ADDRESS, 0.02 ether);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.02 ether
        );
    }

    function test__unit_revert__disperseCaPay__addressHasLessThanAmount()
        external
    {
        addBalance(address(this), ETHER_ADDRESS, 0.002 ether);

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.01 ether,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        toData[1] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.01 ether,
            toAddress: COMMON_USER_NO_STAKER_3.Address
        });

        vm.expectRevert();
        evvm.disperseCaPay(toData, ETHER_ADDRESS, 0.02 ether);

        assertEq(evvm.getBalance(address(this), ETHER_ADDRESS), 0.002 ether);
    }

    function test__unit_revert__disperseCaPay__AmountDeclaredLessThanMetadataTot()
        external
    {
        addBalance(address(this), ETHER_ADDRESS, 0.02 ether);

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.1 ether,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        toData[1] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.1 ether,
            toAddress: COMMON_USER_NO_STAKER_3.Address
        });

        vm.expectRevert();
        evvm.disperseCaPay(toData, ETHER_ADDRESS, 0.02 ether);

        assertEq(evvm.getBalance(address(this), ETHER_ADDRESS), 0.02 ether);
    }

    function test__unit_revert__disperseCaPay__MetadataTotLessThanAmountDeclared()
        external
    {
        addBalance(address(this), ETHER_ADDRESS, 0.02 ether);

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.01 ether,
            toAddress: COMMON_USER_NO_STAKER_2.Address
        });

        toData[1] = EvvmStructs.DisperseCaPayMetadata({
            amount: 0.01 ether,
            toAddress: COMMON_USER_NO_STAKER_3.Address
        });

        vm.expectRevert();
        evvm.disperseCaPay(toData, ETHER_ADDRESS, 0.2 ether);

        assertEq(evvm.getBalance(address(this), ETHER_ADDRESS), 0.02 ether);
    }
}
