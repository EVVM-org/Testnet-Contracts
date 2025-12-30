// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM function revert behavior
 * @notice some functions has evvm functions that are implemented
 *         for payment and dosent need to be tested here
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
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";
import {
    P2PSwapStructs
} from "@evvm/testnet-contracts/contracts/p2pSwap/lib/P2PSwapStructs.sol";

contract unitTestRevert_P2PSwap_adminTools is Test, Constants {
    P2PSwap p2pSwap;

    function executeBeforeSetUp() internal override {
        staking._setupEstimatorAndEvvm(address(estimator), address(evvm));

        treasury = new Treasury(address(evvm));

        evvm._setupNameServiceAndTreasuryAddress(
            address(nameService),
            address(treasury)
        );

        p2pSwap = new P2PSwap(address(evvm), address(staking), ADMIN.Address);

        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
        evvm.setPointStaker(address(p2pSwap), 0x01);
    }

    function addBalance(address user, address token, uint256 amount) private {
        evvm.addBalance(user, token, amount);
    }

    /// @notice Creates an order for testing purposes
    function createOrder(
        AccountData memory executor,
        AccountData memory user,
        uint256 nonceP2PSwap,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 priorityFee,
        uint256 nonceEVVM,
        bool priorityFlag
    ) private returns (uint256 market, uint256 orderId) {
        P2PSwapStructs.MetadataMakeOrder memory orderData = P2PSwapStructs
            .MetadataMakeOrder({
                nonce: nonceP2PSwap,
                tokenA: tokenA,
                tokenB: tokenB,
                amountA: amountA,
                amountB: amountB
            });

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOrder(
                evvm.getEvvmID(),
                nonceP2PSwap,
                tokenA,
                tokenB,
                amountA,
                amountB
            )
        );

        bytes memory signatureP2P = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(p2pSwap),
                "",
                tokenA,
                amountA,
                priorityFee,
                nonceEVVM,
                priorityFlag,
                address(p2pSwap)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        vm.startPrank(executor.Address);
        (market, orderId) = p2pSwap.makeOrder(
            user.Address,
            orderData,
            signatureP2P,
            priorityFee,
            nonceEVVM,
            priorityFlag,
            signatureEVVM
        );
        vm.stopPrank();

        return (market, orderId);
    }

    function test__unit_revert__proposeOwner_notOwner() external {
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeOwner_notProposedUser() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeOwner();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeOwner_proposeExpired() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposeOwner();
        vm.stopPrank();
    }

    function test__unit_revert__acceptOwner_notProposedUser() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
        vm.expectRevert();
        p2pSwap.acceptOwner();
        vm.stopPrank();
    }

    function test__unit_revert__acceptOwner_proposeExpired() external {
        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeOwner(COMMON_USER_NO_STAKER_1.Address);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.acceptOwner();
        vm.stopPrank();
    }

    function test__unit_revert__proposeFillFixedPercentage_notOwner() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__proposeFillFixedPercentage_wrongValues()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 1_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        vm.expectRevert();
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillFixedPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeFillFixedPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillFixedPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);

        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposeFillFixedPercentage();

        vm.stopPrank();
    }

    function test__unit_revert__acceptFillFixedPercentage_notOwner() external {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptFillFixedPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__acceptFillFixedPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);

        p2pSwap.proposeFillFixedPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.acceptFillFixedPercentage();

        vm.stopPrank();
    }

    function test__unit_revert__proposeFillPropotionalPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__proposeFillPropotionalPercentage_wrongValues()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 1_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        vm.expectRevert();
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillPropotionalPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeFillPropotionalPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeFillPropotionalPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposeFillPropotionalPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__acceptFillPropotionalPercentage_notOwner()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptFillPropotionalPercentage();
        vm.stopPrank();
    }

    function test__unit_revert__acceptFillPropotionalPercentage_proposeExpired()
        external
    {
        uint256 sellerPercentage = 1_000;
        uint256 servicePercentage = 8_000;
        uint256 stakerPercentage = 1_000;

        vm.startPrank(ADMIN.Address);

        p2pSwap.proposeFillPropotionalPercentage(
            sellerPercentage,
            servicePercentage,
            stakerPercentage
        );
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.acceptFillPropotionalPercentage();

        vm.stopPrank();
    }

    function test__unit_revert__proposePercentageFee_notOwner() external {
        uint256 fee = 10_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposePercentageFee(fee);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposePercentageFee_notOwner() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposePercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposePercentageFee_proposeExpired()
        external
    {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);

        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.rejectProposePercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptPercentageFee_notOwner() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptPercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptPercentageFee_proposeExpired() external {
        uint256 fee = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposePercentageFee(fee);

        vm.warp(vm.getBlockTimestamp() + 2 days);

        vm.expectRevert();
        p2pSwap.acceptPercentageFee();
        vm.stopPrank();
    }

    function test__unit_revert__proposeMaxLimitFillFixedFee_notOwner()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeMaxLimitFillFixedFee_notOwner()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.stopPrank();
        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeMaxLimitFillFixedFee_proposeExpired()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.warp(vm.getBlockTimestamp() + 2 days);

        vm.expectRevert();
        p2pSwap.rejectProposeMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptMaxLimitFillFixedFee_notOwner() external {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__acceptMaxLimitFillFixedFee_proposeExpired()
        external
    {
        uint256 prop = 10_000;

        vm.startPrank(ADMIN.Address);
        p2pSwap.proposeMaxLimitFillFixedFee(prop);

        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.expectRevert();
        p2pSwap.acceptMaxLimitFillFixedFee();
        vm.stopPrank();
    }

    function test__unit_revert__proposeWithdrawal_notOwner() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();
    }

    function test__unit_revert__proposeWithdrawal_notEnoughBalance() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.000001 ether);

        vm.expectRevert();
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeWithdrawal_notOwner() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.rejectProposeWithdrawal();
        vm.stopPrank();
    }

    function test__unit_revert__rejectProposeWithdrawal_proposeExpired()
        external
    {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);

        vm.warp(vm.getBlockTimestamp() + 2 days);

        vm.expectRevert();
        p2pSwap.rejectProposeWithdrawal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptWithdrawal_notOwner() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);
        vm.stopPrank();

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);
        vm.expectRevert();
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();
    }

    function test__unit_revert__acceptWithdrawal_proposeExpired() external {
        address token = ETHER_ADDRESS;
        uint256 amount = 0.01 ether;
        address to = COMMON_USER_NO_STAKER_1.Address;

        addBalance(address(p2pSwap), token, 0.1 ether);

        vm.startPrank(ADMIN.Address);
        p2pSwap.addBalance(token, 0.1 ether);
        p2pSwap.proposeWithdrawal(token, amount, to);

        vm.warp(vm.getBlockTimestamp() + 2 days);

        vm.expectRevert();
        p2pSwap.acceptWithdrawal();
        vm.stopPrank();
    }
}
