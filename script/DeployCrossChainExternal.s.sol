// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {TreasuryExternalChainStation} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/TreasuryExternalChainStation.sol";
import {CrossChainInputs} from "../input/CrossChainInputs.sol";

contract DeployCrossChainExternalScript is Script, CrossChainInputs {
    TreasuryExternalChainStation treasuryExternal;
    function setUp() public {}

    function run() public {

            vm.startBroadcast();

            treasuryExternal = new TreasuryExternalChainStation(
                adminExternal,
                crosschainConfigExternal
            );

            vm.stopBroadcast();

    }
}
