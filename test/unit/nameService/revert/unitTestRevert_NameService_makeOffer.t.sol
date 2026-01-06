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

contract unitTestRevert_NameService_makeOffer is Test, Constants {
    AccountData COMMON_USER_NO_STAKER_3 = WILDCARD_USER;

    function addBalance(
        AccountData memory user,
        uint256 offerAmount,
        uint256 priorityFeeAmount
    )
        private
        returns (uint256 totalOfferAmount, uint256 totalPriorityFeeAmount)
    {
        evvm.addBalance(
            user.Address,
            PRINCIPAL_TOKEN_ADDRESS,
            offerAmount + priorityFeeAmount
        );

        totalOfferAmount = offerAmount;
        totalPriorityFeeAmount = priorityFeeAmount;
    }

    /**
     * Function to test:
     * bSigAt[variable]: bad signature at
     * bPaySigAt[variable]: bad payment signature at
     * some denominations on test can be explicit expleined
     */

    /*

    function test__unit_revert__makeOffer__bPaySigAt() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
             totalOfferAmount +  priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }


    ////////////////////////////////////////////////////
    function test__unit_revert__makeOffer__bPaySigAt() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();
        
        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
             totalOfferAmount +  priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    */

    function test__unit_revert__makeOffer__bSigAtSigner() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_1.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bSigAtUsername() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "user",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bSigAtExpirationDate() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 1 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bSigAtOfferAmount() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                0.0000001 ether,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bSigAtNonceNameService() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                777
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtSigner() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtToAddress() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(evvm),
                "",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtToIdentity() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(0),
                "nameservice",
                PRINCIPAL_TOKEN_ADDRESS,
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtTokenAddress() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                ETHER_ADDRESS,
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtAmount() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                777,
                priorityFeeAmount,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtPriorityFeeAmount()
        external
    {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                1 ether,
                101,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtNonceEVVM() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                777,
                true,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtPriorityFlag() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                false,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__bPaySigAtExecutor() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );

        bytes memory signatureNameService;
        bytes memory signatureEVVM;
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = vm.sign(
            COMMON_USER_NO_STAKER_2.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001
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
                totalOfferAmount,
                priorityFeeAmount,
                101,
                true,
                address(evvm)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__NonceMnsAlreadyUsed() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_1,
            0.001 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10101,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_1.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10101,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_1.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__identityDoesNotExist() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "fake",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "fake",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__identityIsNotAUsername() external {
        _execute_makePreRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "notuser",
            1,
            99999999999999999999999999999999999
        );

        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                string.concat(
                    "@",
                    AdvancedStrings.bytes32ToString(
                        keccak256(abi.encodePacked("notuser", uint256(1)))
                    )
                ),
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            string.concat(
                "@",
                AdvancedStrings.bytes32ToString(
                    keccak256(abi.encodePacked("notuser", uint256(1)))
                )
            ),
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername(
                string.concat(
                    "@",
                    AdvancedStrings.bytes32ToString(
                        keccak256(abi.encodePacked("notuser", uint256(1)))
                    )
                ),
                0
            );

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__amountToOfferIsZero() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                block.timestamp + 30 days,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp + 30 days,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );
        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }

    function test__unit_revert__makeOffer__expireDateLessThanNow() external {
        (uint256 totalOfferAmount, uint256 priorityFeeAmount) = addBalance(
            COMMON_USER_NO_STAKER_2,
            0.001 ether,
            0.000001 ether
        );
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = _execute_makeMakeOfferSignatures(
                COMMON_USER_NO_STAKER_2,
                "test",
                block.timestamp - 1,
                totalOfferAmount,
                10001,
                priorityFeeAmount,
                101,
                true
            );

        vm.startPrank(COMMON_USER_STAKER.Address);

        vm.expectRevert();
        nameService.makeOffer(
            COMMON_USER_NO_STAKER_2.Address,
            "test",
            block.timestamp - 1,
            totalOfferAmount,
            10001,
            signatureNameService,
            priorityFeeAmount,
            101,
            true,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkData = nameService
            .getSingleOfferOfUsername("test", 0);

        assertEq(checkData.offerer, address(0));
        assertEq(checkData.amount, 0);
        assertEq(checkData.expireDate, 0);

        assertEq(
            evvm.getBalance(
                COMMON_USER_NO_STAKER_2.Address,
                PRINCIPAL_TOKEN_ADDRESS
            ),
            totalOfferAmount + priorityFeeAmount
        );
        assertEq(
            evvm.getBalance(COMMON_USER_STAKER.Address, PRINCIPAL_TOKEN_ADDRESS),
            0
        );
    }
}
