// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

/**

:::::::::: :::    ::: ::::::::: :::::::::      ::::::::::: :::::::::: :::::::: ::::::::::: 
:+:        :+:    :+:      :+:       :+:           :+:     :+:       :+:    :+:    :+:     
+:+        +:+    +:+     +:+       +:+            +:+     +:+       +:+           +:+     
:#::+::#   +#+    +:+    +#+       +#+             +#+     +#++:++#  +#++:++#++    +#+     
+#+        +#+    +#+   +#+       +#+              +#+     +#+              +#+    +#+     
#+#        #+#    #+#  #+#       #+#               #+#     #+#       #+#    #+#    #+#     
###         ########  ######### #########          ###     ########## ########     ###     


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
import {NameServiceStructs} from "@evvm/testnet-contracts/contracts/nameService/lib/NameServiceStructs.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Erc191TestBuilder} from "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {EvvmStorage} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStorage.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";

contract fuzzTest_NameService_withdrawOffer is Test, Constants {
    Staking staking;
    Evvm evvm;
    Estimator estimator;
    Treasury treasury;
    NameService nameService;

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

        makeRegistrationUsername(
            COMMON_USER_NO_STAKER_1,
            "test",
            777,
            10101,
            20202
        );
    }

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(user.Address, MATE_TOKEN_ADDRESS, priorityFeeAmount);

        totalPriorityFeeAmount = priorityFeeAmount;
    }

    function makeRegistrationUsername(
        AccountData memory user,
        string memory username,
        uint256 clowNumber,
        uint256 nonceNameServicePre,
        uint256 nonceNameService
    ) private {
        evvm.addBalance(
            user.Address,
            MATE_TOKEN_ADDRESS,
            nameService.getPriceOfRegistration(username)
        );

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPreRegistrationUsername(
                evvm.getEvvmID(),
                keccak256(abi.encodePacked(username, uint256(clowNumber))),
                nonceNameServicePre
            )
        );

        nameService.preRegistrationUsername(
            user.Address,
            keccak256(abi.encodePacked(username, uint256(clowNumber))),
            nonceNameServicePre,
            Erc191TestBuilder.buildERC191Signature(v, r, s),
            0,
            0,
            false,
            hex""
        );

        skip(30 minutes);

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForRegistrationUsername(
                evvm.getEvvmID(),
                username,
                clowNumber,
                nonceNameService
            )
        );
        bytes memory signatureNameService = Erc191TestBuilder
            .buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                MATE_TOKEN_ADDRESS,
                nameService.getPriceOfRegistration(username),
                0,
                evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
                false,
                address(nameService)
            )
        );
        bytes memory signatureEVVM = Erc191TestBuilder.buildERC191Signature(
            v,
            r,
            s
        );

        nameService.registrationUsername(
            user.Address,
            username,
            clowNumber,
            nonceNameService,
            signatureNameService,
            0,
            evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address),
            false,
            signatureEVVM
        );
    }

    function makeOffer(
        AccountData memory user,
        string memory usernameToMakeOffer,
        uint256 expireDate,
        uint256 amountToOffer,
        uint256 nonceNameService,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    ) private {
        uint8 v;
        bytes32 r;
        bytes32 s;
        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        evvm.addBalance(user.Address, MATE_TOKEN_ADDRESS, amountToOffer);

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForMakeOffer(
                evvm.getEvvmID(),
                usernameToMakeOffer,
                expireDate,
                amountToOffer,
                nonceNameService
            )
        );
        signatureNameService = Erc191TestBuilder.buildERC191Signature(v, r, s);

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                address(nameService),
                "",
                MATE_TOKEN_ADDRESS,
                amountToOffer,
                0,
                nonceEVVM,
                priorityFlagEVVM,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);

        nameService.makeOffer(
            user.Address,
            usernameToMakeOffer,
            expireDate,
            amountToOffer,
            nonceNameService,
            signatureNameService,
            0,
            nonceEVVM,
            priorityFlagEVVM,
            signatureEVVM
        );
    }

    function makeWithdrawOfferSignatures(
        AccountData memory user,
        bool givePriorityFee,
        string memory usernameToFindOffer,
        uint256 index,
        uint256 nonceNameService,
        uint256 priorityFeeAmountEVVM,
        uint256 nonceEVVM,
        bool priorityFlagEVVM
    )
        private
        view
        returns (bytes memory signatureNameService, bytes memory signatureEVVM)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        if (givePriorityFee) {
            (v, r, s) = vm.sign(
                user.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                evvm.getEvvmID(),
                    usernameToFindOffer,
                    index,
                    nonceNameService
                )
            );
            signatureNameService = Erc191TestBuilder.buildERC191Signature(
                v,
                r,
                s
            );

            (v, r, s) = vm.sign(
                user.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForPay(
                evvm.getEvvmID(),
                    address(nameService),
                    "",
                    MATE_TOKEN_ADDRESS,
                    0,
                    priorityFeeAmountEVVM,
                    nonceEVVM,
                    priorityFlagEVVM,
                    address(nameService)
                )
            );
            signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
        } else {
            (v, r, s) = vm.sign(
                user.PrivateKey,
                Erc191TestBuilder.buildMessageSignedForWithdrawOffer(
                evvm.getEvvmID(),
                    usernameToFindOffer,
                    index,
                    nonceNameService
                )
            );
            signatureNameService = Erc191TestBuilder.buildERC191Signature(
                v,
                r,
                s
            );
            signatureEVVM = "";
        }
    }

    /**
     * Function to test:
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    struct WithdrawOfferFuzzTestInput_nPF {
        bool usingUserTwo;
        bool usingFisher;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
    }

    struct WithdrawOfferFuzzTestInput_PF {
        bool usingUserTwo;
        bool usingFisher;
        uint8 nonceNameService;
        uint8 nonceEVVM;
        bool priorityFlagEVVM;
        uint16 priorityFeeAmountEVVM;
    }

    function test__fuzz__withdrawOffer__nPF(
        WithdrawOfferFuzzTestInput_nPF memory input
    ) external {
        vm.assume(input.nonceNameService != 10001 && input.nonceEVVM != 101);

        makeOffer(
            COMMON_USER_NO_STAKER_2,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );

        makeOffer(
            COMMON_USER_NO_STAKER_3,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );

        AccountData memory selectedUser = input.usingUserTwo
            ? COMMON_USER_NO_STAKER_2
            : COMMON_USER_NO_STAKER_3;

        AccountData memory selectedExecuter = input.usingFisher
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_1;

        uint256 indexSelected = input.usingUserTwo ? 0 : 1;

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        (bytes memory signatureNameService, ) = makeWithdrawOfferSignatures(
            selectedUser,
            false,
            "test",
            indexSelected,
            input.nonceNameService,
            0,
            nonceEvvm,
            input.priorityFlagEVVM
        );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        vm.startPrank(selectedExecuter.Address);

        nameService.withdrawOffer(
            selectedUser.Address,
            "test",
            indexSelected,
            input.nonceNameService,
            signatureNameService,
            0,
            nonceEvvm,
            input.priorityFlagEVVM,
            ""
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(selectedUser.Address, MATE_TOKEN_ADDRESS),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(selectedExecuter.Address, MATE_TOKEN_ADDRESS),
            evvm.getRewardAmount() + (((checkDataBefore.amount * 1) / 796))
        );
    }

    function test__fuzz__withdrawOffer__PF(
        WithdrawOfferFuzzTestInput_PF memory input
    ) external {
        vm.assume(
            input.nonceNameService != 10001 &&
                input.nonceEVVM != 101 &&
                input.priorityFeeAmountEVVM != 0
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

        makeOffer(
            COMMON_USER_NO_STAKER_3,
            "test",
            block.timestamp + 30 days,
            0.001 ether,
            10001,
            101,
            true
        );

        AccountData memory selectedUser = input.usingUserTwo
            ? COMMON_USER_NO_STAKER_2
            : COMMON_USER_NO_STAKER_3;

        AccountData memory selectedExecuter = input.usingFisher
            ? COMMON_USER_STAKER
            : COMMON_USER_NO_STAKER_1;

        uint256 indexSelected = input.usingUserTwo ? 0 : 1;

        uint256 nonceEvvm = input.priorityFlagEVVM
            ? input.nonceEVVM
            : evvm.getNextCurrentSyncNonce(selectedUser.Address);

        addBalance(selectedUser, input.priorityFeeAmountEVVM);
        (
            bytes memory signatureNameService,
            bytes memory signatureEVVM
        ) = makeWithdrawOfferSignatures(
                selectedUser,
                true,
                "test",
                indexSelected,
                input.nonceNameService,
                input.priorityFeeAmountEVVM,
                nonceEvvm,
                input.priorityFlagEVVM
            );

        NameService.OfferMetadata memory checkDataBefore = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        vm.startPrank(selectedExecuter.Address);

        nameService.withdrawOffer(
            selectedUser.Address,
            "test",
            indexSelected,
            input.nonceNameService,
            signatureNameService,
            input.priorityFeeAmountEVVM,
            nonceEvvm,
            input.priorityFlagEVVM,
            signatureEVVM
        );

        vm.stopPrank();

        NameService.OfferMetadata memory checkDataAfter = nameService
            .getSingleOfferOfUsername("test", indexSelected);

        assertEq(checkDataAfter.offerer, address(0));
        assertEq(checkDataAfter.amount, checkDataBefore.amount);
        assertEq(checkDataAfter.expireDate, checkDataBefore.expireDate);

        assertEq(
            evvm.getBalance(selectedUser.Address, MATE_TOKEN_ADDRESS),
            checkDataBefore.amount
        );
        assertEq(
            evvm.getBalance(selectedExecuter.Address, MATE_TOKEN_ADDRESS),
            evvm.getRewardAmount() +
                (((checkDataBefore.amount * 1) / 796)) +
                input.priorityFeeAmountEVVM
        );
    }
}
