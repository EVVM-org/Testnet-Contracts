// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Evvm} from "@EVVM/testnet/contracts/evvm/Evvm.sol";
import {Staking} from "@EVVM/testnet/contracts/staking/Staking.sol";
import {Estimator} from "@EVVM/testnet/contracts/staking/Estimator.sol";
import {NameService} from "@EVVM/testnet/contracts/nameService/NameService.sol";
import {EvvmStructs} from "@EVVM/testnet/contracts/evvm/lib/EvvmStructs.sol";
import {TreasuryExternalChainStation} from "@EVVM/testnet/contracts/treasuryTwoChains/TreasuryExternalChainStation.sol";
import {TreasuryHostChainStation} from "@EVVM/testnet/contracts/treasuryTwoChains/TreasuryHostChainStation.sol";
import {HostChainStationStructs} from "@EVVM/testnet/contracts/treasuryTwoChains/lib/HostChainStationStructs.sol";
import {ExternalChainStationStructs} from "@EVVM/testnet/contracts/treasuryTwoChains/lib/ExternalChainStationStructs.sol";

contract DeployTestnetCrossChain is Script {
    Staking sMate;
    Evvm evvm;
    Estimator estimator;
    NameService nameService;
    TreasuryExternalChainStation treasuryExternal;
    TreasuryHostChainStation treasuryHost;
    /*
    
    struct CrosschainConfig {
        uint32 externalChainStationDomainId;
        address mailboxAddress;

        uint32 externalChainStationEid;
        address endpointAddress;

        string externalChainStationChainName;
        address gasServiceAddress;
        address gatewayAddress;
    }
     */
    //config for Sepolia eth
    HostChainStationStructs.CrosschainConfig _crosschainConfigHost =
        HostChainStationStructs.CrosschainConfig({
            externalChainStationDomainId: 421614, //Domain ID for Arb Sepolia on Hyperlane
            mailboxAddress: 0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766, //Mailbox for Host (ETH Sepolia) on Hyperlane
            externalChainStationEid: 40231, //EID for Arb Sepolia on LayerZero
            endpointAddress: 0x6EDCE65403992e310A62460808c4b910D972f10f, //Endpoint for Host (ETH Sepolia) on LayerZero
            externalChainStationChainName: "arbitrum-sepolia", //Chain Name for Arb Sepolia on Axelar
            gasServiceAddress: 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6, //Gas Service for Host (ETH Sepolia) on Axelar
            gatewayAddress: 0xe432150cce91c13a887f7D836923d5597adD8E31 //Gateway for Host (ETH Sepolia) on Axelar
        });

    /*
    struct CrosschainConfig {
        uint32 hostChainStationDomainId;
        address mailboxAddress;
        uint32 hostChainStationEid;
        address endpointAddress;
        string hostChainStationChainName;
        address gasServiceAddress;
        address gatewayAddress;
    } */
    ExternalChainStationStructs.CrosschainConfig _crosschainConfigExternal =
        ExternalChainStationStructs.CrosschainConfig({
            hostChainStationDomainId: 11155111, //Domain ID for ETH Sepolia on Hyperlane
            mailboxAddress: 0x598facE78a4302f11E3de0bee1894Da0b2Cb71F8, //Mailbox for External (ETH Sepolia) on Hyperlane
            hostChainStationEid: 40161, //EID for ETH Sepolia on LayerZero
            endpointAddress: 0x6EDCE65403992e310A62460808c4b910D972f10f, //Endpoint for External (ETH Sepolia) on LayerZero
            hostChainStationChainName: "ethereum-sepolia", //Chain Name for ETH Sepolia on Axelar
            gasServiceAddress: 0xbE406F0189A0B4cf3A05C286473D23791Dd44Cc6, //Gas Service for External (ETH Sepolia) on Axelar
            gatewayAddress: 0xe1cE95479C84e9809269227C7F8524aE051Ae77a //Gateway for External (ETH Sepolia) on Axelar
        });

    address constant ADMIN = 0x5cBf2D4Bbf834912Ad0bD59980355b57695e8309;

    address constant EVVM_ADDRESS = address(0);

    function setUp() public {}

    function run() public {
        EvvmStructs.EvvmMetadata memory inputMetadata = EvvmStructs
            .EvvmMetadata({
                EvvmName: "EVVM Testnet",
                EvvmID: 1,
                principalTokenName: "Mate Test Token",
                principalTokenSymbol: "Mate",
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: 2033333333000000000000000000,
                eraTokens: 1016666666500000000000000000,
                reward: 5000000000000000000
            });

        if (block.chainid == 11155111) {
            vm.startBroadcast();

            sMate = new Staking(ADMIN, ADMIN);
            evvm = new Evvm(ADMIN, address(sMate), inputMetadata);
            estimator = new Estimator(
                ADMIN,
                address(evvm),
                address(sMate),
                ADMIN
            );
            nameService = new NameService(address(evvm), ADMIN);

            treasuryHost = new TreasuryHostChainStation(
                address(evvm),
                ADMIN,
                _crosschainConfigHost
            );

            sMate._setupEstimatorAndEvvm(address(estimator), address(evvm));
            evvm._setupNameServiceAndTreasuryAddress(
                address(nameService),
                address(treasuryHost)
            );

            vm.stopBroadcast();
        } else if (block.chainid == 421614) {
            vm.startBroadcast();

            treasuryExternal = new TreasuryExternalChainStation(
                ADMIN,
                _crosschainConfigExternal,
                0
            );

            vm.stopBroadcast();
        } else {
            console2.log("Wrong chain ID");
        }
    }
}
