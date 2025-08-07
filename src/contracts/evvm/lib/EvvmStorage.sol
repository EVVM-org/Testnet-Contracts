// Copyright (c) 2025 GERMAN MARIA ABAL BAZZANO
// License: EVVM Noncommercial License v1.0 (see LICENSE file)

pragma solidity ^0.8.0;

import {EvvmStructs} from "./EvvmStructs.sol";

/**
 * @title EvvmStorage
 * @author jistro.eth
 * @dev Storage layout contract for EVVM proxy pattern implementation.
 *      This contract inherits all structures from EvvmStructs and
 *      defines the storage layout that will be used by the proxy pattern.
 *
 * @notice This contract should not be deployed directly, it's meant to be
 *         inherited by the implementation contracts to ensure they maintain
 *         the same storage layout.
 */

abstract contract EvvmStorage is EvvmStructs {
    address constant ETH_ADDRESS = address(0);
    bytes1 constant FLAG_IS_STAKER = 0x01;

    address gasServiceAddress;
    address routerCCIP;

    address mailboxHyperlane;

    address nameServiceAddress;

    address stakingContractAddress;

    address whitelistTokenToBeAdded_address;
    address whitelistTokenToBeAdded_pool;
    uint256 whitelistTokenToBeAdded_dateToSet;

    bytes1 breakerSetupNameServiceAddress;

    EvvmMetadata evvmMetadata =
        EvvmMetadata({
            EvvmName: "EVVM",
            EvvmID: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
            principalTokenName: "EVVM Staking Token",
            principalTokenSymbol: "EVVM-STK",
            principalTokenAddress: 0x0000000000000000000000000000000000000001,
            totalSupply: 2033333333000000000000000000,
            eraTokens: 2033333333000000000000000000 / 2,
            reward: 5000000000000000000
        });

    TreasuryMetadata treasuryMetadata;

    AddressTypeProposal admin;

    /**
     * @dev The address of the implementation contract is stored
     *      separately because of the way the proxy pattern works,
     *      rather than in a struct.
     */
    address currentImplementation;
    address proposalImplementation;
    uint256 timeToAcceptImplementation;

    UintTypeProposal maxAmountToWithdraw;

    mapping(address => bytes1) stakerList;

    mapping(address user => mapping(address token => uint256 quantity)) balances;

    mapping(address user => uint256 nonce) nextSyncUsedNonce;

    mapping(address user => mapping(uint256 nonce => bool isUsed)) asyncUsedNonce;

    mapping(address user => uint256 nonce) nextFisherDepositNonce;

    mapping(address user => uint256 nonce) nextFisherWithdrawalNonce;

    mapping(address token => whitheListedTokenMetadata) whitelistedTokens;
}
