import { $ } from "bun";
import { colors } from "../constants";
import {
  promptString,
  promptNumber,
  promptAddress,
  promptYesNo,
} from "./prompts";
import { formatNumber, showError } from "./validators";
import type {
  BaseInputAddresses,
  CrossChainInputs,
  EvvmMetadata,
} from "../types";
import { getRPCUrlAndChainId } from "../utils/rpc";
import { checkCrossChainSupport } from "../utils/crossChain";
import { getAddress } from "viem/utils";

/**
 * Interactive configuration wizard for EVVM deployment.
 * Collects addresses and metadata, validates inputs, and writes to file.
 *
 * @returns {Promise<boolean>} - Returns true if configuration is confirmed and saved, false otherwise.
 */
export async function configurationBasic(): Promise<boolean> {
  let confirmationDone = false;

  let evvmMetadata: EvvmMetadata = {
    EvvmName: "EVVM",
    EvvmID: 0,
    principalTokenName: "Mate Token",
    principalTokenSymbol: "MATE",
    principalTokenAddress: "0x0000000000000000000000000000000000000001",
    totalSupply: 2033333333000000000000000000,
    eraTokens: 1016666666500000000000000000,
    reward: 5000000000000000000,
  };

  let addresses: BaseInputAddresses = {
    admin: null,
    goldenFisher: null,
    activator: null,
  };

  while (!confirmationDone) {
    for (const key of Object.keys(addresses) as (keyof BaseInputAddresses)[]) {
      addresses[key] = promptAddress(
        `${colors.yellow}Enter the ${key} address:${colors.reset}`
      );
    }

    evvmMetadata.EvvmName = promptString(
      `${colors.yellow}EVVM Name ${colors.darkGray}[${evvmMetadata.EvvmName}]:${colors.reset}`,
      evvmMetadata.EvvmName ?? undefined
    );

    evvmMetadata.principalTokenName = promptString(
      `${colors.yellow}Principal Token Name ${colors.darkGray}[${evvmMetadata.principalTokenName}]:${colors.reset}`,
      evvmMetadata.principalTokenName ?? undefined
    );

    evvmMetadata.principalTokenSymbol = promptString(
      `${colors.yellow}Principal Token Symbol ${colors.darkGray}[${evvmMetadata.principalTokenSymbol}]:${colors.reset}`,
      evvmMetadata.principalTokenSymbol ?? undefined
    );

    if (
      promptYesNo(
        `${colors.yellow}Configure advanced metadata (totalSupply, eraTokens, reward)? (y/n):${colors.reset}`
      ).toLowerCase() === "y"
    ) {
      evvmMetadata.totalSupply = promptNumber(
        `${colors.yellow}Total Supply ${colors.darkGray}[${formatNumber(
          evvmMetadata.totalSupply
        )}]:${colors.reset}`,
        evvmMetadata.totalSupply ?? undefined
      );

      evvmMetadata.eraTokens = promptNumber(
        `${colors.yellow}Era Tokens ${colors.darkGray}[${formatNumber(
          evvmMetadata.eraTokens
        )}]:${colors.reset}`,
        evvmMetadata.eraTokens ?? undefined
      );

      evvmMetadata.reward = promptNumber(
        `${colors.yellow}Reward ${colors.darkGray}[${formatNumber(
          evvmMetadata.reward
        )}]:${colors.reset}`,
        evvmMetadata.reward ?? undefined
      );
    }

    console.log(
      `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
    );
    console.log(
      `${colors.bright}          Configuration Summary${colors.reset}`
    );
    console.log(
      `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
    );

    console.log(`${colors.bright}Addresses:${colors.reset}`);
    for (const key of Object.keys(addresses) as (keyof BaseInputAddresses)[]) {
      console.log(`  ${colors.blue}${key}:${colors.reset} ${addresses[key]}`);
    }

    console.log(`\n${colors.bright}EVVM Metadata:${colors.reset}`);
    for (const [metaKey, metaValue] of Object.entries(evvmMetadata)) {
      if (metaKey === "EvvmID") continue;

      let displayValue = metaValue;
      if (typeof metaValue === "number" && metaValue > 1e15) {
        displayValue = metaValue.toLocaleString("fullwide", {
          useGrouping: false,
        });
      }
      console.log(`  ${colors.blue}${metaKey}:${colors.reset} ${displayValue}`);
    }
    console.log();

    confirmationDone =
      promptYesNo(
        `${colors.yellow}Confirm configuration? (y/n):${colors.reset}`
      ).toLowerCase() === "y";
  }

  if (!(await writeBaseInputsFile(addresses, evvmMetadata))) {
    showError(
      "Failed to write inputs file.",
      `Please try again. If the issue persists, create an issue on GitHub:\n${colors.blue}https://github.com/EVVM-org/Playgrounnd-Contracts/issues${colors.reset}`
    );
    return false;
  }

  console.log(
    `\n${colors.green}✓${colors.reset} Input configuration saved to ${colors.darkGray}./input/BaseInputs.sol${colors.reset}`
  );

  return true;
}

/**
 * Interactive cross-chain configuration wizard for EVVM deployment.
 * Collects external and host chain data, validates inputs, and writes to file.
 *
 * @returns {Promise<{externalRpcUrl: string | null; externalChainId: number | null; hostRpcUrl: string | null; hostChainId: number | null}>} - Returns external and host RPC URLs and chain IDs if configuration is confirmed and saved, nulls otherwise.
 */
export async function configurationCrossChain(): Promise<{
  externalRpcUrl: string | null;
  externalChainId: number | null;
  hostRpcUrl: string | null;
  hostChainId: number | null;
}> {
  let confirmationCrossChainDone = false;
  let crossChainInputs: CrossChainInputs = {
    adminExternal: "0x0000000000000000000000000000000000000000",
    crosschainConfigHost: {
      hyperlane: {
        externalChainStationDomainId: 0,
        mailboxAddress: "0x0000000000000000000000000000000000000000",
      },
      layerZero: {
        externalChainStationEid: 0,
        endpointAddress: "0x0000000000000000000000000000000000000000",
      },
      axelar: {
        externalChainStationChainName: "",
        gatewayAddress: "0x0000000000000000000000000000000000000000",
        gasServiceAddress: "0x0000000000000000000000000000000000000000",
      },
    },
    crosschainConfigExternal: {
      hyperlane: {
        hostChainStationDomainId: 0,
        mailboxAddress: "0x0000000000000000000000000000000000000000",
      },
      layerZero: {
        hostChainStationEid: 0,
        endpointAddress: "0x0000000000000000000000000000000000000000",
      },
      axelar: {
        hostChainStationChainName: "",
        gatewayAddress: "0x0000000000000000000000000000000000000000",
        gasServiceAddress: "0x0000000000000000000000000000000000000000",
      },
    },
  };

  let externalRpcUrl: string | null = null;
  let externalChainId: number | null = null;
  let hostRpcUrl: string | null = null;
  let hostChainId: number | null = null;

  while (!confirmationCrossChainDone) {
    ({ rpcUrl: externalRpcUrl, chainId: externalChainId } =
      await getRPCUrlAndChainId(process.env.EXTERNAL_RPC_URL)),
      `${colors.yellow}Please enter the External Chain RPC URL:${colors.reset}`;

    let externalChainData = await checkCrossChainSupport(externalChainId!);

    if (!externalChainData)
      return {
        externalRpcUrl: null,
        externalChainId: null,
        hostRpcUrl: null,
        hostChainId: null,
      };

    ({ rpcUrl: hostRpcUrl, chainId: hostChainId } = await getRPCUrlAndChainId(
      process.env.HOST_RPC_URL,
      `${colors.yellow}Please enter the Host Chain RPC URL:${colors.reset}`
    ));

    let hostChainData = await checkCrossChainSupport(hostChainId!);

    if (!hostChainData)
      return {
        externalRpcUrl: null,
        externalChainId: null,
        hostRpcUrl: null,
        hostChainId: null,
      };

    let addressAdminExternal = promptAddress(
      `${colors.yellow}Enter the external admin address:${colors.reset}`
    );

    crossChainInputs = {
      adminExternal: addressAdminExternal,
      crosschainConfigHost: {
        hyperlane: {
          externalChainStationDomainId: externalChainData.Hyperlane.DomainId,
          mailboxAddress: externalChainData.Hyperlane
            .MailboxAddress as `0x${string}`,
        },
        layerZero: {
          externalChainStationEid: externalChainData.LayerZero.EId,
          endpointAddress: externalChainData.LayerZero
            .EndpointAddress as `0x${string}`,
        },
        axelar: {
          externalChainStationChainName: externalChainData.Axelar.ChainName,
          gatewayAddress: externalChainData.Axelar.Gateway as `0x${string}`,
          gasServiceAddress: externalChainData.Axelar
            .GasService as `0x${string}`,
        },
      },
      crosschainConfigExternal: {
        hyperlane: {
          hostChainStationDomainId: hostChainData.Hyperlane.DomainId,
          mailboxAddress: hostChainData.Hyperlane
            .MailboxAddress as `0x${string}`,
        },
        layerZero: {
          hostChainStationEid: hostChainData.LayerZero.EId,
          endpointAddress: hostChainData.LayerZero
            .EndpointAddress as `0x${string}`,
        },
        axelar: {
          hostChainStationChainName: hostChainData.Axelar.ChainName,
          gatewayAddress: hostChainData.Axelar.Gateway as `0x${string}`,
          gasServiceAddress: hostChainData.Axelar.GasService as `0x${string}`,
        },
      },
    };

    console.log(
      `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
    );
    console.log(
      `${colors.bright}      Cross-Chain Configuration Summary${colors.reset}`
    );
    console.log(
      `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
    );

    console.log(`${colors.bright}External Admin:${colors.reset}`);
    console.log(
      `  ${colors.blue}${crossChainInputs.adminExternal}${colors.reset}`
    );

    console.log(
      `\n${colors.bright}Host Chain Station (${hostChainData.Chain}):${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Hyperlane External Domain ID: ${colors.blue}${crossChainInputs.crosschainConfigHost.hyperlane.externalChainStationDomainId}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Hyperlane Mailbox: ${colors.blue}${crossChainInputs.crosschainConfigHost.hyperlane.mailboxAddress}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} LayerZero External EId: ${colors.blue}${crossChainInputs.crosschainConfigHost.layerZero.externalChainStationEid}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} LayerZero Endpoint: ${colors.blue}${crossChainInputs.crosschainConfigHost.layerZero.endpointAddress}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Axelar External Chain: ${colors.blue}${crossChainInputs.crosschainConfigHost.axelar.externalChainStationChainName}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Axelar Gateway: ${colors.blue}${crossChainInputs.crosschainConfigHost.axelar.gatewayAddress}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Axelar Gas Service: ${colors.blue}${crossChainInputs.crosschainConfigHost.axelar.gasServiceAddress}${colors.reset}`
    );

    console.log(
      `\n${colors.bright}External Chain Station (${externalChainData.Chain}):${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Hyperlane Host Domain ID: ${colors.blue}${crossChainInputs.crosschainConfigExternal.hyperlane.hostChainStationDomainId}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Hyperlane Mailbox: ${colors.blue}${crossChainInputs.crosschainConfigExternal.hyperlane.mailboxAddress}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} LayerZero Host EId: ${colors.blue}${crossChainInputs.crosschainConfigExternal.layerZero.hostChainStationEid}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} LayerZero Endpoint: ${colors.blue}${crossChainInputs.crosschainConfigExternal.layerZero.endpointAddress}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Axelar Host Chain: ${colors.blue}${crossChainInputs.crosschainConfigExternal.axelar.hostChainStationChainName}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Axelar Gateway: ${colors.blue}${crossChainInputs.crosschainConfigExternal.axelar.gatewayAddress}${colors.reset}`
    );
    console.log(
      `  ${colors.darkGray}→${colors.reset} Axelar Gas Service: ${colors.blue}${crossChainInputs.crosschainConfigExternal.axelar.gasServiceAddress}${colors.reset}`
    );
    console.log();

    if (
      promptYesNo(
        `${colors.yellow}Confirm cross-chain configuration? (y/n):${colors.reset}`
      ).toLowerCase() === "y"
    ) {
      confirmationCrossChainDone = true;
    }
  }

  if (!(await writeCrossChainInputsFile(crossChainInputs))) {
    showError(
      "Failed to write cross-chain inputs file.",
      `Please try again. If the issue persists, create an issue on GitHub:\n${colors.blue}https://github.com/EVVM-org/Playgrounnd-Contracts/issues${colors.reset}`
    );
    return {
      externalRpcUrl: null,
      externalChainId: null,
      hostRpcUrl: null,
      hostChainId: null,
    };
  }

  console.log(
    `${colors.green}✓${colors.reset} Cross-chain input configuration saved to ${colors.darkGray}./input/CrossChainInputs.sol${colors.reset}\n`
  );

  return {
    externalRpcUrl: externalRpcUrl!,
    externalChainId: externalChainId!,
    hostRpcUrl: hostRpcUrl!,
    hostChainId: hostChainId!,
  };
}

/**
 * Generates and writes the BaseInputs.sol file with deployment configuration
 *
 * Creates a Solidity contract containing all deployment parameters including
 * admin addresses and EVVM metadata. This file is used by the deployment script.
 *
 * @param {BaseInputAddresses} addresses - Admin, golden fisher, and activator addresses
 * @param {EvvmMetadata} evvmMetadata - EVVM configuration including token economics
 * @returns {Promise<boolean>} True if file was written successfully
 */
export async function writeBaseInputsFile(
  addresses: BaseInputAddresses,
  evvmMetadata: EvvmMetadata
): Promise<boolean> {
  const inputDir = "./input";
  const inputFile = `${inputDir}/BaseInputs.sol`;

  if (
    addresses.admin == undefined ||
    addresses.goldenFisher == undefined ||
    addresses.activator == undefined
  )
    return false;

  try {
    await Bun.file(inputFile).text();
  } catch {
    await $`mkdir -p ${inputDir}`.quiet();
    await Bun.write(inputFile, "");
    console.log(`${colors.blue}Created ${inputFile}${colors.reset}`);
  }

  

  const inputFileContent = `// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";

abstract contract BaseInputs {
    address admin = ${getAddress(addresses.admin)};
    address goldenFisher = ${getAddress(addresses.goldenFisher)};
    address activator = ${getAddress(addresses.activator)};

    EvvmStructs.EvvmMetadata inputMetadata =
        EvvmStructs.EvvmMetadata({
            EvvmName: "${evvmMetadata.EvvmName}",
            // evvmID will be set to 0, and it will be assigned when you register the evvm
            EvvmID: 0,
            principalTokenName: "${evvmMetadata.principalTokenName}",
            principalTokenSymbol: "${evvmMetadata.principalTokenSymbol}",
            principalTokenAddress: ${evvmMetadata.principalTokenAddress},
            totalSupply: ${formatNumber(evvmMetadata.totalSupply)},
            eraTokens: ${formatNumber(evvmMetadata.eraTokens)},
            reward: ${formatNumber(evvmMetadata.reward)}
        });
}
`;

  await Bun.write(inputFile, inputFileContent);
  return true;
}

/**
 * Generates and writes the CrossChainInputs.sol file with cross-chain configuration
 *
 * Creates a Solidity contract containing all cross-chain messaging parameters for
 * both host and external chain stations. Used by cross-chain deployment scripts.
 *
 * @param {CrossChainInputs} crossChainInputs - Cross-chain configuration for Hyperlane, LayerZero, and Axelar
 * @returns {Promise<boolean>} True if file was written successfully
 */
export async function writeCrossChainInputsFile(
  crossChainInputs: CrossChainInputs
): Promise<boolean> {
  const inputDir = "./input";
  const inputFile = `${inputDir}/CrossChainInputs.sol`;

  try {
    await Bun.file(inputFile).text();
  } catch {
    await $`mkdir -p ${inputDir}`.quiet();
    await Bun.write(inputFile, "");
    console.log(`${colors.blue}Created ${inputFile}${colors.reset}`);
  }

  const inputFileContent = `// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {HostChainStationStructs} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/lib/HostChainStationStructs.sol";
import {ExternalChainStationStructs} from "@evvm/testnet-contracts/contracts/treasuryTwoChains/lib/ExternalChainStationStructs.sol";

abstract contract CrossChainInputs {
    address constant adminExternal = ${getAddress(
      crossChainInputs.adminExternal
    )};

    HostChainStationStructs.CrosschainConfig crosschainConfigHost =
        HostChainStationStructs.CrosschainConfig({
            hyperlane: HostChainStationStructs.HyperlaneConfig({
                externalChainStationDomainId: ${
                  crossChainInputs.crosschainConfigHost.hyperlane
                    .externalChainStationDomainId
                }, //Domain ID for External on Hyperlane
                externalChainStationAddress: bytes32(0), //External Chain Station Address on Hyperlane
                mailboxAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.hyperlane
                    .mailboxAddress
                )} //Mailbox for Host on Hyperlane
            }),
            layerZero: HostChainStationStructs.LayerZeroConfig({
                externalChainStationEid: ${
                  crossChainInputs.crosschainConfigHost.layerZero
                    .externalChainStationEid
                }, //EID for External on LayerZero
                externalChainStationAddress: bytes32(0), //External Chain Station Address on LayerZero
                endpointAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.layerZero
                    .endpointAddress
                )} //Endpoint for Host on LayerZero
            }),
            axelar: HostChainStationStructs.AxelarConfig({
                externalChainStationChainName: "${
                  crossChainInputs.crosschainConfigHost.axelar
                    .externalChainStationChainName
                }", //Chain Name for External on Axelar
                externalChainStationAddress: "", //External Chain Station Address on Axelar
                gasServiceAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.axelar
                    .gasServiceAddress
                )}, //Gas Service for External on Axelar
                gatewayAddress: ${getAddress(
                  crossChainInputs.crosschainConfigExternal.axelar
                    .gatewayAddress
                )} //Gateway for Host on Axelar
            })
        });

    ExternalChainStationStructs.CrosschainConfig crosschainConfigExternal =
        ExternalChainStationStructs.CrosschainConfig({
            hyperlane: ExternalChainStationStructs.HyperlaneConfig({
                hostChainStationDomainId: ${
                  crossChainInputs.crosschainConfigExternal.hyperlane
                    .hostChainStationDomainId
                }, //Domain ID for Host on Hyperlane
                hostChainStationAddress: bytes32(0), //Host Chain Station Address on Hyperlane
                mailboxAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.hyperlane.mailboxAddress
                )} //Mailbox for External on Hyperlane
            }),
            layerZero: ExternalChainStationStructs.LayerZeroConfig({
                hostChainStationEid: ${
                  crossChainInputs.crosschainConfigExternal.layerZero
                    .hostChainStationEid
                }, //EID for Host on LayerZero
                hostChainStationAddress: bytes32(0), //Host Chain Station Address on LayerZero
                endpointAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.layerZero
                    .endpointAddress
                )} //Endpoint for External on LayerZero
            }),
            axelar: ExternalChainStationStructs.AxelarConfig({
                hostChainStationChainName: "${
                  crossChainInputs.crosschainConfigExternal.axelar
                    .hostChainStationChainName
                }", //Chain Name for Host on Axelar
                hostChainStationAddress: "", //Host Chain Station Address on Axelar
                gasServiceAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.axelar.gasServiceAddress
                )}, //Gas Service for External on Axelar
                gatewayAddress: ${getAddress(
                  crossChainInputs.crosschainConfigHost.axelar.gatewayAddress
                )} //Gateway for External on Axelar
            })
        });
}
`;

  await Bun.write(inputFile, inputFileContent);
  return true;
}
