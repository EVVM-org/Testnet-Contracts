// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {EvvmStructs} from "./EvvmStructs.sol";

/**
 * @title EvvmStorage
 * @author Mate labs
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

    address nameServiceAddress;

    address stakingContractAddress;

    address treasuryAddress;

    address whitelistTokenToBeAdded_address;
    address whitelistTokenToBeAdded_pool;
    uint256 whitelistTokenToBeAdded_dateToSet;

    /**
     * @dev The address of the implementation contract is stored
     *      separately because of the way the proxy pattern works,
     *      rather than in a struct.
     */
    address currentImplementation;
    address proposalImplementation;
    uint256 timeToAcceptImplementation;

    uint256 windowTimeToChangeEvvmID;

    EvvmMetadata evvmMetadata;

    AddressTypeProposal admin;

    bytes1 breakerSetupNameServiceAddress;

    mapping(address => bytes1) stakerList;

    mapping(address user => mapping(address token => uint256 quantity)) balances;

    mapping(address user => uint256 nonce) nextSyncUsedNonce;

    mapping(address user => mapping(uint256 nonce => bool isUsed)) asyncUsedNonce;

    mapping(address user => uint256 nonce) nextFisherDepositNonce;
}
