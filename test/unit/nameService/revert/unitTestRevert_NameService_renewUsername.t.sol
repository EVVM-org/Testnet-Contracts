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
    AdvancedStrings
} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {
    EvvmStructs
} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {
    Treasury
} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract unitTestRevert_NameService_renewUsername is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function addBalance(
        AccountData memory user,
        string memory username,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalRenewalAmount, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            nameService.seePriceToRenew(username) + priorityFeeAmount
        );

        totalRenewalAmount = nameService.seePriceToRenew(username);
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * bSigAt[variable]: bad signature at
     * bPaySigAt[variable]: bad payment signature at
     * some denominations on test can be explicit expleined
     */

    /*
    function test__unit_revert__renewUsername__bPaySigAt() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService.getIdentityBasicMetadata(
            "test"
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService.getIdentityBasicMetadata(
            "test"
        );

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    ///////////

    function test__unit_revert__renewUsername__() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                1000001000001,
                totalPriorityFeeAmount,
                11111111,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService.getIdentityBasicMetadata(
            "test"
        );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService.getIdentityBasicMetadata(
            "test"
        );

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }
    */

    function test__unit_revert__renewUsername__bSigAtSigner() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bSigAtUsername() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "user",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bSigAtNonceNameService()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtSigner() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtToAddress() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtToIdentity() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtTokenAddress()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtAmount() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                1,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtPriorityFee() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                1 ether,
                11111111,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtNonceEVVM() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                777,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtPriorityFlag()
        external
    {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                false,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__bPaySigAtExecutor() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRenewUsername(
                evvm.getEvvmID(),
                "test",
                1000001000001
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
                totalRenewalAmount,
                totalPriorityFeeAmount,
                11111111,
                true,
                address(0)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__userIsNotTheOwner() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_2, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                1000001000001,
                totalPriorityFeeAmount,
                11111111,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__nonceAlreadyUsed() external {
        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "test", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                10101,
                totalPriorityFeeAmount,
                11111111,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            10101,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__notAUsername() external {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "notausername",
            777,
            999
        );

        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(
                COMMON_USER_NO_STAKER_1,
                string.concat(
                    "@",
                    AdvancedStrings.bytes32ToString(
                        keccak256(
                            abi.encodePacked("notausername", uint256(777))
                        )
                    )
                ),
                0.001 ether
            );

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "test@mail.com",
                1000001000001,
                totalPriorityFeeAmount,
                11111111,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test@mail.com");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "test@mail.com",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("test@mail.com");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__renewUsername__expirationDateMoreThan100Years()
        external
    {

        _execute_makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "user",
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff0),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff1),
            uint256(0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff2)
        );
    
        for (uint256 i = 0; i < 99; i++) {
            addBalance(COMMON_USER_NO_STAKER_1, "user", 0);

            (
                bytes memory _signatureNameService,
                bytes memory _signatureEVVM
            ) = _execute_makeRenewUsernameSignatures(
                    COMMON_USER_NO_STAKER_1,
                    "user",
                    1000001000001000000 + i,
                    0,
                    1000001000001000000 + i,
                    true
                );

            vm.startPrank(COMMON_USER_STAKER.Address);

            
            nameService.renewUsername(
                COMMON_USER_NO_STAKER_1.Address,
                "user",
                1000001000001000000 + i,
                _signatureNameService,
                0,
                1000001000001000000 + i,
                true,
                _signatureEVVM
            );

            vm.stopPrank();
        }

        (
            uint256 totalRenewalAmount,
            uint256 totalPriorityFeeAmount
        ) = addBalance(COMMON_USER_NO_STAKER_1, "user", 0.001 ether);

        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeRenewUsernameSignatures(
                COMMON_USER_NO_STAKER_1,
                "user",
                1000001000001,
                totalPriorityFeeAmount,
                11111111,
                true
            );

        (, uint256 beforeUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("user");

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.renewUsername(
            COMMON_USER_NO_STAKER_1.Address,
            "user",
            1000001000001,
            signatureNameService,
            totalPriorityFeeAmount,
            11111111,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        (, uint256 afterUsernameExpirationTime) = nameService
            .getIdentityBasicMetadata("user");

        assertEq(afterUsernameExpirationTime, beforeUsernameExpirationTime);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalRenewalAmount + totalPriorityFeeAmount
        );
        
    }
}
