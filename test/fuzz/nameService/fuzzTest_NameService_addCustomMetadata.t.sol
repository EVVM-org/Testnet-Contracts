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

contract fuzzTest_NameService_addCustomMetadata is Test, Constants {
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

        makeRegistrationUsername(COMMON_USER_NO_STAKER_1, "test", 777, 11, 22);
    }

    function addBalance(
        AccountData memory user,
        uint256 priorityFeeAmount
    ) private returns (uint256 totalPriorityFeeAmount) {
        evvm.addBalance(
            user.Address,
            MATE_TOKEN_ADDRESS,
            nameService.getPriceToAddCustomMetadata() + priorityFeeAmount
        );
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

    function makeAddCustomMetadataSignatures(
        AccountData memory user,
        string memory username,
        string memory customMetadata,
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

        (v, r, s) = vm.sign(
            user.PrivateKey,
            Erc191TestBuilder.buildMessageSignedForAddCustomMetadata(
                evvm.getEvvmID(),
                username,
                customMetadata,
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
                nameService.getPriceToAddCustomMetadata(),
                priorityFeeAmountEVVM,
                nonceEVVM,
                priorityFlagEVVM,
                address(nameService)
            )
        );
        signatureEVVM = Erc191TestBuilder.buildERC191Signature(v, r, s);
    }

    function getARandomCustomMetadata(
        uint256 seed
    ) internal view returns (string memory customMetadata) {
        for (uint i = 0; i < 10; i++) {
            customMetadata = string(
                abi.encodePacked(
                    customMetadata,
                    AdvancedStrings.uintToString(
                        uint256(
                            keccak256(
                                abi.encodePacked(
                                    customMetadata,
                                    seed,
                                    block.timestamp
                                )
                            )
                        ) % 10
                    )
                )
            );
        }
    }

    /**
     * Naming Convention for Fuzz Test Functions
     * Basic Structure:
     * test__[typeOfTest]__[functionName]__[options]
     * General Rules:
     *  - Always start with "test__"
     *  - The name of the function to be executed must immediately follow "test__"
     *  - Options are added at the end, separated by underscores
     *
     * Options for Payment Functions:
     * Add these options at the end of the name, in the following order:
     *  a) Priority Fee:
     *      PF: Includes priority fee
     *      nPF: No priority fee
     *  b) Executor:
     *      EX: Includes executor execution
     *      nEX: Does not include executor execution
     *  d) Identity:
     *     ID: Uses a NameService identity
     *     AD: Uses an address
     *
     * Example:
     * test__pay_noStaker_sync__PF_nEX
     *
     * Example explanation:
     * Function to test: payNoStaker_sync
     * PF: Includes priority fee
     * nEX: Does not include executor execution
     *
     * Notes:
     * Separate different parts of the name with double underscores (__)
     */

    /**
     * Function to test:
     * nS: No staker
     * S: Staker
     * PF: Includes priority fee
     * nPF: No priority fee
     */

    struct AddCustomMetadataFuzzTestInput_nPF {
        uint16 nonceNameService;
        uint16 nonceEVVM;
        uint16 seed;
        bool priorityFlagEVVM;
    }

    struct AddCustomMetadataFuzzTestInput_PF {
        uint16 nonceNameService;
        uint16 nonceEVVM;
        uint16 seed;
        uint16 priorityFee;
        bool priorityFlagEVVM;
    }

    function test__fuzz__addCustomMetadata__nS_nPF(
        AddCustomMetadataFuzzTestInput_nPF memory input
    ) external {
        input.nonceNameService = uint16(
            bound(input.nonceNameService, 1000, type(uint16).max - 10)
        );
        input.nonceEVVM = uint16(
            bound(input.nonceEVVM, 1000, type(uint16).max - 10)
        );

        vm.assume(input.nonceNameService != input.nonceEVVM);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        uint256 nonce;
        string memory customMetadata;

        for (uint i = 0; i < 4; i++) {
            addBalance(COMMON_USER_NO_STAKER_1, 0);
            customMetadata = getARandomCustomMetadata(input.seed + i);

            nonce = input.priorityFlagEVVM
                ? input.nonceEVVM + i
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

            (
                signatureNameService,
                signatureEVVM
            ) = makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                customMetadata,
                input.nonceNameService + i,
                0,
                nonce,
                input.priorityFlagEVVM
            );

            vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
            nameService.addCustomMetadata(
                COMMON_USER_NO_STAKER_1.Address,
                "test",
                customMetadata,
                input.nonceNameService + i,
                signatureNameService,
                0,
                nonce,
                input.priorityFlagEVVM,
                signatureEVVM
            );
            vm.stopPrank();

            assertEq(
                bytes(nameService.getSingleCustomMetadataOfIdentity("test", i))
                    .length,
                bytes(customMetadata).length
            );

            assertEq(
                keccak256(
                    bytes(
                        nameService.getSingleCustomMetadataOfIdentity("test", i)
                    )
                ),
                keccak256(bytes(customMetadata))
            );

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    MATE_TOKEN_ADDRESS
                ),
                0
            );
            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_2.Address,
                    MATE_TOKEN_ADDRESS
                ),
                0
            );
        }
    }

    function test__fuzz__addCustomMetadata__nS_PF(
        AddCustomMetadataFuzzTestInput_PF memory input
    ) external {
        input.nonceNameService = uint16(
            bound(input.nonceNameService, 1000, type(uint16).max - 10)
        );
        input.nonceEVVM = uint16(
            bound(input.nonceEVVM, 1000, type(uint16).max - 10)
        );

        vm.assume(input.nonceNameService != input.nonceEVVM);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        uint256 nonce;
        string memory customMetadata;

        for (uint i = 0; i < 4; i++) {
            addBalance(COMMON_USER_NO_STAKER_1, input.priorityFee);
            customMetadata = getARandomCustomMetadata(input.seed + i);

            nonce = input.priorityFlagEVVM
                ? input.nonceEVVM + i
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

            (
                signatureNameService,
                signatureEVVM
            ) = makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                customMetadata,
                input.nonceNameService + i,
                input.priorityFee,
                nonce,
                input.priorityFlagEVVM
            );

            vm.startPrank(COMMON_USER_NO_STAKER_2.Address);
            nameService.addCustomMetadata(
                COMMON_USER_NO_STAKER_1.Address,
                "test",
                customMetadata,
                input.nonceNameService + i,
                signatureNameService,
                input.priorityFee,
                nonce,
                input.priorityFlagEVVM,
                signatureEVVM
            );
            vm.stopPrank();

            assertEq(
                bytes(nameService.getSingleCustomMetadataOfIdentity("test", i))
                    .length,
                bytes(customMetadata).length
            );

            assertEq(
                keccak256(
                    bytes(
                        nameService.getSingleCustomMetadataOfIdentity("test", i)
                    )
                ),
                keccak256(bytes(customMetadata))
            );

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    MATE_TOKEN_ADDRESS
                ),
                0
            );
            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_2.Address,
                    MATE_TOKEN_ADDRESS
                ),
                0
            );
        }
    }

    function test__fuzz__addCustomMetadata__S_nPF(
        AddCustomMetadataFuzzTestInput_nPF memory input
    ) external {
        input.nonceNameService = uint16(
            bound(input.nonceNameService, 1000, type(uint16).max - 10)
        );
        input.nonceEVVM = uint16(
            bound(input.nonceEVVM, 1000, type(uint16).max - 10)
        );

        vm.assume(input.nonceNameService != input.nonceEVVM);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        uint256 nonce;
        string memory customMetadata;

        uint256 amountBeforeExecution;

        for (uint i = 0; i < 4; i++) {
            addBalance(COMMON_USER_NO_STAKER_1, 0);
            customMetadata = getARandomCustomMetadata(input.seed + i);

            nonce = input.priorityFlagEVVM
                ? input.nonceEVVM + i
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

            (
                signatureNameService,
                signatureEVVM
            ) = makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                customMetadata,
                input.nonceNameService + i,
                0,
                nonce,
                input.priorityFlagEVVM
            );

            amountBeforeExecution = evvm.getBalance(
                COMMON_USER_STAKER.Address,
                MATE_TOKEN_ADDRESS
            );
            vm.startPrank(COMMON_USER_STAKER.Address);
            nameService.addCustomMetadata(
                COMMON_USER_NO_STAKER_1.Address,
                "test",
                customMetadata,
                input.nonceNameService + i,
                signatureNameService,
                0,
                nonce,
                input.priorityFlagEVVM,
                signatureEVVM
            );
            vm.stopPrank();

            assertEq(
                bytes(nameService.getSingleCustomMetadataOfIdentity("test", i))
                    .length,
                bytes(customMetadata).length
            );

            assertEq(
                keccak256(
                    bytes(
                        nameService.getSingleCustomMetadataOfIdentity("test", i)
                    )
                ),
                keccak256(bytes(customMetadata))
            );

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    MATE_TOKEN_ADDRESS
                ),
                0
            );
            assertEq(
                evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
                amountBeforeExecution +
                    ((5 * evvm.getRewardAmount()) +
                        ((nameService.getPriceToAddCustomMetadata() * 50) /
                            100))
            );
        }
    }

    function test__fuzz__addCustomMetadata__S_PF(
        AddCustomMetadataFuzzTestInput_PF memory input
    ) external {
        input.nonceNameService = uint16(
            bound(input.nonceNameService, 1000, type(uint16).max - 10)
        );
        input.nonceEVVM = uint16(
            bound(input.nonceEVVM, 1000, type(uint16).max - 10)
        );

        vm.assume(input.nonceNameService != input.nonceEVVM);

        bytes memory signatureNameService;
        bytes memory signatureEVVM;

        uint256 nonce;
        string memory customMetadata;

        uint256 amountBeforeExecution;

        for (uint i = 0; i < 4; i++) {
            addBalance(COMMON_USER_NO_STAKER_1, input.priorityFee);
            customMetadata = getARandomCustomMetadata(input.seed + i);

            nonce = input.priorityFlagEVVM
                ? input.nonceEVVM + i
                : evvm.getNextCurrentSyncNonce(COMMON_USER_NO_STAKER_1.Address);

            (
                signatureNameService,
                signatureEVVM
            ) = makeAddCustomMetadataSignatures(
                COMMON_USER_NO_STAKER_1,
                "test",
                customMetadata,
                input.nonceNameService + i,
                input.priorityFee,
                nonce,
                input.priorityFlagEVVM
            );

            amountBeforeExecution = evvm.getBalance(
                COMMON_USER_STAKER.Address,
                MATE_TOKEN_ADDRESS
            );
            vm.startPrank(COMMON_USER_STAKER.Address);
            nameService.addCustomMetadata(
                COMMON_USER_NO_STAKER_1.Address,
                "test",
                customMetadata,
                input.nonceNameService + i,
                signatureNameService,
                input.priorityFee,
                nonce,
                input.priorityFlagEVVM,
                signatureEVVM
            );
            vm.stopPrank();

            assertEq(
                bytes(nameService.getSingleCustomMetadataOfIdentity("test", i))
                    .length,
                bytes(customMetadata).length
            );

            assertEq(
                keccak256(
                    bytes(
                        nameService.getSingleCustomMetadataOfIdentity("test", i)
                    )
                ),
                keccak256(bytes(customMetadata))
            );

            assertEq(
                evvm.getBalance(
                    COMMON_USER_NO_STAKER_1.Address,
                    MATE_TOKEN_ADDRESS
                ),
                0
            );
            assertEq(
                evvm.getBalance(COMMON_USER_STAKER.Address, MATE_TOKEN_ADDRESS),
                amountBeforeExecution +
                    ((5 * evvm.getRewardAmount()) +
                        ((nameService.getPriceToAddCustomMetadata() * 50) /
                            100) +
                        input.priorityFee)
            );
        }
    }
}
