// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {Estimator} from "@evvm/testnet-contracts/contracts/staking/Estimator.sol";
import {NameService} from "@evvm/testnet-contracts/contracts/nameService/NameService.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {Treasury} from "@evvm/testnet-contracts/contracts/treasury/Treasury.sol";
import {P2PSwap} from "@evvm/testnet-contracts/contracts/p2pSwap/P2PSwap.sol";

contract DeployTestnet is Script {
    Staking staking;
    Evvm evvm;
    Estimator estimator;
    NameService nameService;
    Treasury treasury;
    P2PSwap p2pSwap;

    struct AddressData {
        address activator;
        address admin;
        address goldenFisher;
    }

    struct BasicMetadata {
        string EvvmName;
        string principalTokenName;
        string principalTokenSymbol;
    }

    struct AdvancedMetadata {
        uint256 eraTokens;
        uint256 reward;
        uint256 totalSupply;
    }

    function setUp() public {}

    function run() public {
        string memory path = "input/address.json";
        assert(vm.isFile(path));
        string memory data = vm.readFile(path);
        bytes memory dataJson = vm.parseJson(data);

        AddressData memory addressData = abi.decode(dataJson, (AddressData));

        path = "input/evvmBasicMetadata.json";
        assert(vm.isFile(path));
        data = vm.readFile(path);
        dataJson = vm.parseJson(data);

        BasicMetadata memory basicMetadata = abi.decode(
            dataJson,
            (BasicMetadata)
        );

        path = "input/evvmAdvancedMetadata.json";
        assert(vm.isFile(path));
        data = vm.readFile(path);
        dataJson = vm.parseJson(data);

        AdvancedMetadata memory advancedMetadata = abi.decode(
            dataJson,
            (AdvancedMetadata)
        );

        console2.log("Admin:", addressData.admin);
        console2.log("GoldenFisher:", addressData.goldenFisher);
        console2.log("Activator:", addressData.activator);
        console2.log("EvvmName:", basicMetadata.EvvmName);
        console2.log("PrincipalTokenName:", basicMetadata.principalTokenName);
        console2.log(
            "PrincipalTokenSymbol:",
            basicMetadata.principalTokenSymbol
        );
        console2.log("TotalSupply:", advancedMetadata.totalSupply);
        console2.log("EraTokens:", advancedMetadata.eraTokens);
        console2.log("Reward:", advancedMetadata.reward);

        EvvmStructs.EvvmMetadata memory inputMetadata = EvvmStructs
            .EvvmMetadata({
                EvvmName: basicMetadata.EvvmName,
                EvvmID: 0, ///@dev dont change the EvvmID unless you know what you are doing
                principalTokenName: basicMetadata.principalTokenName,
                principalTokenSymbol: basicMetadata.principalTokenSymbol,
                principalTokenAddress: 0x0000000000000000000000000000000000000001,
                totalSupply: advancedMetadata.totalSupply,
                eraTokens: advancedMetadata.eraTokens,
                reward: advancedMetadata.reward
            });

        vm.startBroadcast();

        staking = new Staking(addressData.admin, addressData.goldenFisher);
        evvm = new Evvm(addressData.admin, address(staking), inputMetadata);
        estimator = new Estimator(
            addressData.activator,
            address(evvm),
            address(staking),
            addressData.admin
        );
        nameService = new NameService(address(evvm), addressData.admin);

        treasury = new Treasury(address(evvm));

        staking._setupEstimatorAndEvvm(address(estimator), address(evvm));
        evvm._setupNameServiceAndTreasuryAddress(address(nameService), address(treasury));

        p2pSwap = new P2PSwap(address(evvm), address(staking), addressData.admin);
        vm.stopBroadcast();

        console2.log("Staking deployed at:", address(staking));
        console2.log("Evvm deployed at:", address(evvm));
        console2.log("Estimator deployed at:", address(estimator));
        console2.log("NameService deployed at:", address(nameService));
        console2.log("Treasury deployed at:", address(treasury));
        console2.log("P2PSwap deployed at:", address(p2pSwap));
        
    }
}
