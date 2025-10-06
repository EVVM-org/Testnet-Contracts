// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title TreasuryStructs
 * @dev Library of common structures used across TreasuryTwoChains.
 *      This contract serves as a shared type system for the entire ecosystem,
 *      ensuring consistency in data structures between the core TreasuryTwoChains and
 *      external service contracts.
 *
 * @notice This contract should be inherited by both TreasuryTwoChains contracts
 *         that need to interact with these data structures.
 */

abstract contract HostChainStationStructs {
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    struct HyperlaneConfig {
        uint32 externalChainStationDomainId;
        bytes32 externalChainStationAddress;
        address mailboxAddress;
    }

    struct LayerZeroConfig {
        uint32 externalChainStationEid;
        bytes32 externalChainStationAddress;
        address endpointAddress;
    }

    struct AxelarConfig {
        string externalChainStationChainName;
        string externalChainStationAddress;
        address gasServiceAddress;
        address gatewayAddress;
    }

    struct CrosschainConfig {
        uint32 externalChainStationDomainId;
        address mailboxAddress;
        uint32 externalChainStationEid;
        address endpointAddress;
        string externalChainStationChainName;
        address gasServiceAddress;
        address gatewayAddress;
    }
}
