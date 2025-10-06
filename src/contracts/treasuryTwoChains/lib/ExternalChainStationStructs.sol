// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

abstract contract ExternalChainStationStructs {
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    struct HyperlaneConfig {
        uint32 hostChainStationDomainId;
        bytes32 hostChainStationAddress;
        address mailboxAddress;
    }

    struct LayerZeroConfig {
        uint32 hostChainStationEid;
        bytes32 hostChainStationAddress;
        address endpointAddress;
    }

    struct AxelarConfig {
        string hostChainStationChainName;
        string hostChainStationAddress;
        address gasServiceAddress;
        address gatewayAddress;
    }

    struct CrosschainConfig {
        uint32 hostChainStationDomainId;
        address mailboxAddress;
        uint32 hostChainStationEid;
        address endpointAddress;
        string hostChainStationChainName;
        address gasServiceAddress;
        address gatewayAddress;
    }
}
