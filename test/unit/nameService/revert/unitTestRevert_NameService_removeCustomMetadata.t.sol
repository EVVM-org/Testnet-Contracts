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
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestRevert_NameService_removeCustomMetadata is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function executeBeforeSetUp() internal override {
        evvm.setPointStaker(COMMON_USER_STAKER.Address, 0x01);

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101,
            20202
        );

        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>1",
            11,
            11,
            true
        );
        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>2",
            22,
            22,
            true
        );
        _execute_makeAddCustomMetadata(
            COMMON_USER_NO_STAKER_1,
            "test",
            "test>3",
            33,
            33,
            true
        );
    }

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    )
        private
        returns (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        )
    {
        evvm.addBalance(
            user.Address,
            MATE_TOKEN_ADDRESS,
            nameService.getPriceToRemoveCustomMetadata() + priorityFeeAmount
        );

        totalPriceRemovedCustomMetadata = nameService
            .getPriceToRemoveCustomMetadata();
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * bSigAt[variable]: bad signature at
     * bPaySigAt[variable]: bad payment signature at
     * some denominations on test can be explicit expleined
     */

    /*
    function test__unit_revert__removeCustomMetadata__bSigAt() external {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                evvm.getEvvmID(),
                "test",
                1,
                100010001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                MATE_TOKEN_ADDRESS,
                nameService.getPriceToRemoveCustomMetadata(),
                totalPriorityFeeAmount,
                100010001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService.getSingleCustomMetadataOfIdentity(
            "test",
            1
        );

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    //////////////////////////////////////////////////////////////////////

    function test__unit_revert__removeCustomMetadata__S_PF() external {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1,
                100010001,
                totalPriorityFeeAmount,
                100010001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService.getSingleCustomMetadataOfIdentity(
            "test",
            1
        );

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }
    */

    function test__unit_revert__removeCustomMetadata__bSigAtSigner() external {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                evvm.getEvvmID(),
                "test",
                1,
                100010001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                MATE_TOKEN_ADDRESS,
                nameService.getPriceToRemoveCustomMetadata(),
                totalPriorityFeeAmount,
                100010001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 1);

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__removeCustomMetadata__bSigAtUsername()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                evvm.getEvvmID(),
                "user",
                1,
                100010001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                MATE_TOKEN_ADDRESS,
                nameService.getPriceToRemoveCustomMetadata(),
                totalPriorityFeeAmount,
                100010001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 1);

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__removeCustomMetadata__bSigAtIndex() external {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                evvm.getEvvmID(),
                "test",
                777,
                100010001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                MATE_TOKEN_ADDRESS,
                nameService.getPriceToRemoveCustomMetadata(),
                totalPriorityFeeAmount,
                100010001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 1);

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__removeCustomMetadata__bSigAtNonceNameService()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRemoveCustomMetadata(
                evvm.getEvvmID(),
                "test",
                1,
                777
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                MATE_TOKEN_ADDRESS,
                nameService.getPriceToRemoveCustomMetadata(),
                totalPriorityFeeAmount,
                100010001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 1);

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__removeCustomMetadata__notOwnerOfUsername()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_2, 0.0001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                1,
                100010001,
                totalPriorityFeeAmount,
                100010001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 1);

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__removeCustomMetadata__nonceAlreadyUsed()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1,
                11,
                totalPriorityFeeAmount,
                100010001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            11,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 1);

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__removeCustomMetadata__indexMoreThanMax()
        external
    {
        (
            uint256 totalPriceRemovedCustomMetadata,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, 0.0001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                777,
                100010001,
                totalPriorityFeeAmount,
                100010001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            777,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            totalPriceRemovedCustomMetadata + totalPriorityFeeAmount
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__removeCustomMetadata__userDontHaveFunds()
        external
    {
        uint256 totalPriorityFeeAmount = 0;

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRemoveCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1,
                100010001,
                totalPriorityFeeAmount,
                100010001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.removeCustomMetadata(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            100010001,
            signatureNameService,
            totalPriorityFeeAmount,
            100010001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        string memory customMetadata = nameService
            .getSingleCustomMetadataOfIdentity("test", 1);

        assertEq(bytes(customMetadata).length, bytes("test>2").length);
        assertEq(keccak256(bytes(customMetadata)), keccak256(bytes("test>2")));

        assertEq(nameService.getCustomMetadataMaxSlotsOfIdentity("test"), 3);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                MATE_TOKEN_ADDRESS
            ),
            0
        );

        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
            0
        );
    }
}
