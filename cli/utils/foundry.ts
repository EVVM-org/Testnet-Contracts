/**
 * Foundry Integration Utilities
 * 
 * Provides functions for interacting with Foundry toolchain including:
 * - Contract deployment and verification
 * - Wallet management and validation
 * - Registry contract interactions
 * - Solidity file generation
 * 
 * @module cli/utils/foundry
 */

import { $ } from "bun";
import type { InputAddresses, EvvmMetadata, CreatedContract } from "../types";
import {
  colors,
  EthSepoliaPublicRpc,
  RegisteryEvvmAddress,
} from "../constants";
import { formatNumber, showError } from "./validators";

/**
 * Generates and writes the Inputs.sol file with deployment configuration
 * 
 * Creates a Solidity contract containing all deployment parameters including
 * admin addresses and EVVM metadata. This file is used by the deployment script.
 * 
 * @param {InputAddresses} addresses - Admin, golden fisher, and activator addresses
 * @param {EvvmMetadata} evvmMetadata - EVVM configuration including token economics
 * @returns {Promise<boolean>} True if file was written successfully
 */
export async function writeInputsFile(
  addresses: InputAddresses,
  evvmMetadata: EvvmMetadata
): Promise<boolean> {
  const inputDir = "./input";
  const inputFile = `${inputDir}/Inputs.sol`;

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

abstract contract Inputs {
    address admin = ${addresses.admin};
    address goldenFisher = ${addresses.goldenFisher};
    address activator = ${addresses.activator};

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
 * Checks if a chain ID is registered in the EVVM Registry
 * 
 * Queries the EVVM Registry contract on Ethereum Sepolia to verify if the
 * target chain ID is supported for EVVM deployments.
 * 
 * @param {number} chainId - The chain ID to check
 * @returns {Promise<boolean | undefined>} True if registered, false if not, undefined on error
 */
export async function isChainIdRegistered(
  chainId: number
): Promise<boolean | undefined> {
  try {
    const result =
      await $`cast call ${RegisteryEvvmAddress} --rpc-url ${EthSepoliaPublicRpc} "isChainIdRegistered(uint256)(bool)" ${chainId}`.quiet();
    const isSupported = result.stdout.toString().trim() === "true";
    return isSupported;
  } catch (error) {
    console.error(
      `${colors.red}Error checking chain ID support:${colors.reset}`,
      error
    );
    return undefined;
  }
}

/**
 * Registers an EVVM instance in the EVVM Registry contract
 * 
 * Calls the registry contract to register the EVVM instance and receive a unique
 * EVVM ID. This ID is used to identify the EVVM instance across the ecosystem.
 * 
 * @param {number} hostChainId - Chain ID where the EVVM is deployed
 * @param {`0x${string}`} evvmAddress - Address of the deployed EVVM contract
 * @param {string} walletName - Foundry wallet name to use for the transaction
 * @param {string} ethRpcUrl - Ethereum Sepolia RPC URL for registry interaction
 * @returns {Promise<number | undefined>} The assigned EVVM ID, or undefined on error
 */
export async function callRegisterEvvm(
  hostChainId: number,
  evvmAddress: `0x${string}`,
  walletName: string = "defaultKey",
  ethRpcUrl: string = EthSepoliaPublicRpc
): Promise<number | undefined> {
  try {
    const result =
      await $`cast call ${RegisteryEvvmAddress} --rpc-url ${ethRpcUrl} "registerEvvm(uint256,address)(uint256)" ${hostChainId} ${evvmAddress} --account ${walletName}`.quiet();
    await $`cast send ${RegisteryEvvmAddress} --rpc-url ${ethRpcUrl} "registerEvvm(uint256,address)(uint256)" ${hostChainId} ${evvmAddress} --account  ${walletName}`;

    const evvmID = result.stdout.toString().trim();
    return Number(evvmID);
  } catch (error) {
    return undefined;
  }
}

/**
 * Sets the EVVM ID on the deployed EVVM contract
 * 
 * After receiving an EVVM ID from the registry, this function updates the
 * EVVM contract with its assigned ID. Required to complete EVVM initialization.
 * 
 * @param {`0x${string}`} evvmAddress - Address of the EVVM contract
 * @param {number} evvmID - The EVVM ID assigned by the registry
 * @param {string} hostChainRpcUrl - RPC URL for the chain where EVVM is deployed
 * @param {string} walletName - Foundry wallet name to use for the transaction
 * @returns {Promise<boolean>} True if successfully set, false on error
 */
export async function callSetEvvmID(
  evvmAddress: `0x${string}`,
  evvmID: number,
  hostChainRpcUrl: string,
  walletName: string = "defaultKey"
): Promise<boolean> {
  try {
    await $`cast send ${evvmAddress} --rpc-url ${hostChainRpcUrl} "setEvvmID(uint256)" ${evvmID} --account ${walletName} `;
    console.log(
      `${colors.evvmGreen}EVVM ID set successfully on the EVVM contract.${colors.reset}`
    );
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Verifies Foundry installation and wallet setup
 * 
 * Performs prerequisite checks before deployment:
 * 1. Verifies Foundry toolchain is installed
 * 2. Verifies the specified wallet exists in Foundry keystore
 * 
 * @param {string} walletName - Name of the wallet to verify
 * @returns {Promise<boolean>} True if all prerequisites are met, false otherwise
 */
export async function verifyFoundryInstalledAndAccountSetup(
  walletName: string = "defaultKey"
): Promise<boolean> {
  if (!(await foundryIsInstalled())) {
      showError(
        "Foundry is not installed.",
        "Please install Foundry to proceed with deployment."
      );
      return false;
    }
  
    if (!(await walletIsSetup(walletName))) {
      showError(
        `Wallet '${walletName}' is not available.`,
        `Please import your wallet using:\n   ${colors.evvmGreen}cast wallet import ${walletName} --interactive${colors.reset}\n\n   You'll be prompted to enter your private key securely.`
      );
      return false;
    }
  return true;
}

/**
 * Checks if Foundry toolchain is installed
 * 
 * @returns {Promise<boolean>} True if Foundry is installed and accessible
 */
export async function foundryIsInstalled(): Promise<boolean> {
  try {
    await $`foundryup --version`.quiet();
  } catch (error) {
    return false;
  }
  return true;
}

/**
 * Checks if a wallet exists in Foundry's keystore
 * 
 * @param {string} walletName - Name of the wallet to check
 * @returns {Promise<boolean>} True if wallet exists in keystore
 */
export async function walletIsSetup(walletName: string = "defaultKey"): Promise<boolean> {
  let walletList = await $`cast wallet list`.quiet();
  if (!walletList.stdout.includes(`${walletName} (Local)`)) {
    return false;
  }
  return true;
}

/**
 * Displays deployed contracts and extracts EVVM contract address
 * 
 * Reads the Foundry broadcast file to:
 * 1. Extract all deployed contract addresses
 * 2. Display them in a formatted list
 * 3. Locate and return the EVVM contract address
 * 
 * @param {number} chainId - Chain ID where contracts were deployed
 * @returns {Promise<`0x${string}` | null>} EVVM contract address, or null if not found
 */
export async function showDeployContractsAndFindEvvm(
  chainId: number
): Promise<`0x${string}` | null> {
  const broadcastFile = `./broadcast/Deploy.s.sol/${chainId}/run-latest.json`;
  const broadcastContent = await Bun.file(broadcastFile).text();
  const broadcastJson = JSON.parse(broadcastContent);

  const createdContracts = broadcastJson.transactions
    .filter((tx: any) => tx.transactionType === "CREATE")
    .map(
      (tx: any) =>
        ({
          contractName: tx.contractName,
          contractAddress: tx.contractAddress,
        } as CreatedContract)
    );

  console.log(`\n${colors.bright}═══════════════════════════════════════${colors.reset}`);
  console.log(`${colors.bright}          Deployed Contracts${colors.reset}`);
  console.log(`${colors.bright}═══════════════════════════════════════${colors.reset}\n`);
  
  createdContracts.forEach((contract: CreatedContract) => {
    console.log(
      `  ${colors.green}✓${colors.reset} ${colors.blue}${contract.contractName}${colors.reset}\n    ${colors.darkGray}→${colors.reset} ${contract.contractAddress}`
    );
  });
  console.log();

  return (
    createdContracts.find(
      (contract: CreatedContract) => contract.contractName === "Evvm"
    )?.contractAddress ?? null
  );
}
