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

contract unitTestRevert_NameService_acceptOffer is Test, Constants {
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
        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );
    }

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(user.Address, PRINCIPAL_TOKEN_ADDRESS, priorityFeeAmount);

        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * bSigAt[variable]: bad signature at
     * bPaySigAt[variable]: bad payment signature at
     * some denominations on test can be explicit expleined
     */

    /*
    function test__unit_revert__acceptOffer__bPaySigAt() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    /////////////////////////////////////////////////////////////////////////////

    function test__unit_revert__acceptOffer__() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                true,
                "test",
                0,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }
    */

    function test__unit_revert__acceptOffer__bSigAtSigner() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bSigAtUsername() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "user",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bSigAtOfferID() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                1,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bSigAtNonceNameService() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
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
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtSigner() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtToAddress() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtToIdentity() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(0),
                "nameservice",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtTokenAddress() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                ETHER_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtAmount() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                777,
                0,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtPriorityFee() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                1,
                1001,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtNonceEVVM() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                777,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtPriorityFlag() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                false,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__bPaySigAtExecutor() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAcceptOffer(
                evvm.getEvvmID(),
                "test",
                0,
                10000000001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                amountPriorityFee,
                0,
                1001,
                true,
                address(0)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__userIsNotOwner() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                true,
                "test",
                0,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            0,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__nonceMnsAlreadyUsed() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                true,
                "test",
                0,
                10101,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            0,
            10101,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__offerExpired() external {
        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 5 days,
            0.001 ether,
            777,
            777,
            true
        );

        skip(10 days);

        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                true,
                "test",
                1,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__acceptOffer__offerOutOfBounds() external {
        uint256 amountPriorityFee = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether
        );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeAcceptOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                true,
                "test",
                1,
                10000000001,
                amountPriorityFee,
                1001,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();

        nameService.acceptOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1,
            10000000001,
            signatureNameService,
            amountPriorityFee,
            1001,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (address user, ) = nameService.getIdentityBasicMetadata("test");

        assertEq(user, COMMON_USER_NO_STAKER_1.Address);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            amountPriorityFee
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }
}
