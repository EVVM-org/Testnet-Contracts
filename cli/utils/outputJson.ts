/**
 * Output JSON Utilities
 *
 * Provides functions for saving deployment information to JSON files.
 * Creates and manages the output directory for storing deployment artifacts.
 *
 * @module cli/utils/outputJson
 */

import { mkdir, writeFile } from "fs/promises";
import { existsSync } from "fs";
import { join } from "path";
import type { CreatedContract } from "../types";
import { colors } from "../constants";
import { confirmation, warning } from "./outputMesages";

/**
 * Saves deployed contracts to a JSON file in the output directory
 *
 * Creates the output directory if it doesn't exist, then saves all deployed
 * contract information to a JSON file with the specified name. The file
 * includes metadata such as deployment timestamp and chain information.
 *
 * @param {string} fileName - Name for the output file (without .json extension)
 * @param {CreatedContract[]} contracts - Array of deployed contracts with names and addresses
 * @param {number} chainId - Chain ID where contracts were deployed
 * @param {string} [chainName] - Optional human-readable chain name
 * @returns {Promise<void>} Resolves when file is successfully written
 *
 * @example
 * ```typescript
 * const contracts = [
 *   { contractName: "Evvm", contractAddress: "0x..." },
 *   { contractName: "Staking", contractAddress: "0x..." }
 * ];
 * await saveDeploymentToJson("my-deployment", contracts, 11155111, "Sepolia");
 * // Creates: ./output/my-deployment.json
 * ```
 */
export async function saveDeploymentToJson(
  fileName: string,
  contracts: CreatedContract[],
  chainId: number,
  chainName?: string
): Promise<void> {
  console.log(`${colors.bright}Saving deployment information to JSON...${colors.reset}\n`);
  try {
    const outputDir = join(process.cwd(), "output");

    // Create output directory if it doesn't exist
    if (!existsSync(outputDir)) {
      warning("Output directory not found", "Creating directory...");
      await mkdir(outputDir, { recursive: true });
    }

    // Prepare the output data
    const outputData = {
      deploymentName: fileName,
      timestamp: new Date().toISOString(),
      chain: {
        chainId,
        chainName: chainName || `Chain ${chainId}`,
      },
      contracts: contracts.map((contract) => ({
        name: contract.contractName,
        address: contract.contractAddress,
      })),
    };

    // Construct file path
    const filePath = join(outputDir, `${fileName}.json`);

    // Write to file with pretty formatting
    await writeFile(filePath, JSON.stringify(outputData, null, 2), "utf-8");

    confirmation(
      `Deployment information saved to: ${colors.blue}${filePath}${colors.reset}`
    );
  } catch (err) {
    warning(
      "Failed to save deployment information", `${err instanceof Error ? err.message : "Unknown error"}`
    );
  }
}

/**
 * Saves cross-chain deployment to a JSON file
 *
 * Similar to saveDeploymentToJson but handles deployments across two chains
 * (host and external). Organizes contracts by chain and includes metadata
 * for both chains.
 *
 * @param {string} fileName - Name for the output file (without .json extension)
 * @param {CreatedContract[]} hostContracts - Contracts deployed on host chain
 * @param {number} hostChainId - Host chain ID
 * @param {string} [hostChainName] - Optional host chain name
 * @param {CreatedContract[]} externalContracts - Contracts deployed on external chain
 * @param {number} externalChainId - External chain ID
 * @param {string} [externalChainName] - Optional external chain name
 * @returns {Promise<void>} Resolves when file is successfully written
 *
 * @example
 * ```typescript
 * await saveCrossChainDeploymentToJson(
 *   "cross-chain-treasury",
 *   hostContracts, 11155111, "Sepolia",
 *   externalContracts, 421614, "Arbitrum Sepolia"
 * );
 * // Creates: ./output/cross-chain-treasury.json
 * ```
 */
export async function saveCrossChainDeploymentToJson(
  fileName: string,
  hostContracts: CreatedContract[],
  hostChainId: number,
  hostChainName: string | undefined,
  externalContracts: CreatedContract[],
  externalChainId: number,
  externalChainName: string | undefined
): Promise<void> {
  console.log(`${colors.bright}Saving cross-chain deployment information to JSON...${colors.reset}\n`);
  try {
    const outputDir = join(process.cwd(), "output");

    // Create output directory if it doesn't exist
    if (!existsSync(outputDir)) {
      warning("Output directory not found", "Creating directory...");
      await mkdir(outputDir, { recursive: true });
    }

    // Prepare the output data
    const outputData = {
      deploymentName: fileName,
      deploymentType: "cross-chain",
      timestamp: new Date().toISOString(),
      hostChain: {
        chainId: hostChainId,
        chainName: hostChainName || `Chain ${hostChainId}`,
        contracts: hostContracts.map((contract) => ({
          name: contract.contractName,
          address: contract.contractAddress,
        })),
      },
      externalChain: {
        chainId: externalChainId,
        chainName: externalChainName || `Chain ${externalChainId}`,
        contracts: externalContracts.map((contract) => ({
          name: contract.contractName,
          address: contract.contractAddress,
        })),
      },
    };

    // Construct file path
    const filePath = join(outputDir, `${fileName}.json`);

    // Write to file with pretty formatting
    await writeFile(filePath, JSON.stringify(outputData, null, 2), "utf-8");

    confirmation(
      `Cross-chain deployment information saved to: ${colors.blue}${filePath}${colors.reset}`
    );
  } catch (err) {
    warning(
      "Failed to save cross-chain deployment information", `${err instanceof Error ? err.message : "Unknown error"}`
    );
  }
}