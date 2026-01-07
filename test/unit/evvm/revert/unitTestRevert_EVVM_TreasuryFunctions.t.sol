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
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/evvm/lib/ErrorsLib.sol";
contract unitTestRevert_EVVM_TreasuryFunctions is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    //function executeBeforeSetUp() internal override {}

    function test__unit_revert__addAmountToUser__SenderIsNotTreasury() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(ErrorsLib.SenderIsNotTreasury.selector);
        evvm.addAmountToUser(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            100000000000 ether
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0,
            "Sender balance must be 0 because is not the Treasury.sol"
        );
    }

    function test__unit_revert__removeAmountFromUser__SenderIsNotTreasury() external {
        evvm.addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, 10 ether);
        
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(ErrorsLib.SenderIsNotTreasury.selector);
        evvm.addAmountToUser(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            10 ether
        );

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            10 ether,
            "Sender balance must be 10 ether because is not the Treasury.sol"
        );
    }


}
