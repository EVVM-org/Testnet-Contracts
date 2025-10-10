// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {RegistryEvvm} from "@EVVM/testnet/contracts/registryEvvm/RegistryEvvm.sol";


contract DeployRegistryEvvm is Script {
    RegistryEvvm registryEvvm;
    ERC1967Proxy proxyRegistryEvvm;

    // first superuser address is dev.jistro.eth
    address constant SUPERUSER = 0x5cBf2D4Bbf834912Ad0bD59980355b57695e8309;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        registryEvvm = new RegistryEvvm();
        proxyRegistryEvvm = new ERC1967Proxy(address(registryEvvm), "");

        RegistryEvvm(address(proxyRegistryEvvm)).initialize(SUPERUSER);

        vm.stopBroadcast();

        console2.log("RegistryEvvm implementation:", address(registryEvvm));
        console2.log("RegistryEvvm proxy:", address(proxyRegistryEvvm));
    }
}
