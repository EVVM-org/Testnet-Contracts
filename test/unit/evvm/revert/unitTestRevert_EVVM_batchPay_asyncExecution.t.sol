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
import {
    NameServiceStructs
} from "@evvm/testnet-contracts/contracts/nameService/lib/NameServiceStructs.sol";
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

contract unitTestRevert_EVVM_payMultiple_asyncExecution is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);
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
     * For the signature tes we going to assume the executor is a bad actor,
     * but in the executor test an fisher try to execute the payment who obivously
     * is not the executor.
     * Function to test:
     * bSigAt[section]: incorrect signature // bad signature
     * wValAt[section]: wrong value
     * some denominations on test can be explicit expleined
     */

    function test__unit_revert__payMultiple_asyncExecution__bSigAtFrom() public {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_3.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtToAddress()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_3.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtToIdentity()
        public
    {
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
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(0),
                "dummy",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: address(0),
            to_identity: "fake",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtTokenAddress()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: MATE_TOKEN_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtAmount() public {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtPriorityFee()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.07 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtNonce() public {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 777,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtFlagPriority()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: false,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__bSigAtExecutor()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: address(0),
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__diferentExecutor()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                COMMON_USER_STAKER.Address
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: COMMON_USER_STAKER.Address,
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_NO_STAKER_2.Address);

        (uint256 successfulTransactions, ) = evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(successfulTransactions, 0);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__amountMoreThanBalance()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                1 ether,
                0.01 ether,
                1001,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: address(0),
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        (uint256 successfulTransactions, ) = evvm.payMultiple(payData);

        vm.stopPrank();

        console2.log("successfulTransactions:", successfulTransactions);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__priorityFeeMoreThanBalance()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.1 ether,
            0.01 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](1);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.1 ether,
                1001,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.1 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: address(0),
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        (uint256 successfulTransactions, ) = evvm.payMultiple(payData);

        vm.stopPrank();

        assertEq(successfulTransactions , 0);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }

    function test__unit_revert__payMultiple_asyncExecution__nonceAlreadyUsed()
        public
    {
        addBalance(
            COMMON_USER_NO_STAKER_1.Address,
            ETHER_ADDRESS,
            0.2 ether,
            0.02 ether
        );

        EvvmStructs.PayData[] memory payData = new EvvmStructs.PayData[](2);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                COMMON_USER_NO_STAKER_2.Address,
                "",
                ETHER_ADDRESS,
                0.1 ether,
                0.01 ether,
                1001,
                true,
                address(0)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        payData[0] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: address(0),
            signature: signatureEVVM
        });

        payData[1] = EvvmStructs.PayData({
            from: COMMON_USER_NO_STAKER_1.Address,
            to_address: COMMON_USER_NO_STAKER_2.Address,
            to_identity: "",
            token: ETHER_ADDRESS,
            amount: 0.1 ether,
            priorityFee: 0.01 ether,
            nonce: 1001,
            priorityFlag: true,
            executor: address(0),
            signature: signatureEVVM
        });

        vm.startPrank(COMMON_USER_STAKER.Address);

        (uint256 successfulTransactions, bool[] memory results) = evvm.payMultiple(
            payData
        );

        vm.stopPrank();

        assertEq(successfulTransactions , 1);

        assertEq(results[1], false);

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.11 ether
        );
    }
}
