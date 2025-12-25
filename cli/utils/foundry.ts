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
import type {
  CreatedContract,
  ContractFileMetadata,
} from "../types";
import {
  colors,
  EthSepoliaPublicRpc,
  RegisteryEvvmAddress,
  ChainData,
} from "../constants";
import {showError } from "./validators";
import { getAddress } from "viem/utils";



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
  const ethRpcUrl =
    process.env.EVVM_REGISTRATION_RPC_URL?.trim() || EthSepoliaPublicRpc;
  try {
    const result =
      await $`cast call ${RegisteryEvvmAddress} --rpc-url ${ethRpcUrl} "isChainIdRegistered(uint256)(bool)" ${chainId}`.quiet();
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
  evvmAddress: string,
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
  contractAddress: string,
  evvmID: number,
  hostChainRpcUrl: string,
  walletName: string = "defaultKey"
): Promise<boolean> {
  try {
    await $`cast send ${contractAddress} --rpc-url ${hostChainRpcUrl} "setEvvmID(uint256)" ${evvmID} --account ${walletName} `;
    console.log(
      `${colors.evvmGreen}EVVM ID set successfully on the EVVM contract.${colors.reset}`
    );
    return true;
  } catch (error) {
    return false;
  }
}

/**
 * Sets the host chain station address on the external chain station contract
 *
 * @param {`0x${string}`} treasuryExternalChainAddress - Address of the External Chain Station contract
 * @param {`0x${string}`} treasuryHostChainStationAddress - Address of the Host Chain Station
 * @param {string} externalChainRpcUrl - RPC URL for the external chain
 * @param {string} walletName - Foundry wallet name to use for the transaction
 * @returns {Promise<boolean>} True if successfully set, false on error
 */
export async function callConnectStations(
  treasuryHostChainStationAddress: string,
  hostChainRpcUrl: string,
  hostWalletName: string = "defaultKey",
  treasuryExternalChainAddress: string,
  externalChainRpcUrl: string,
  externalWalletName: string = "defaultKey"
): Promise<boolean> {

  try {
    const commandHost = [
      "cast",
      "send",
      treasuryHostChainStationAddress,
      "--rpc-url",
      hostChainRpcUrl,
      "_setExternalChainAddress(address,string)",
      treasuryExternalChainAddress,
      `"${getAddress(treasuryExternalChainAddress)}"`,
      "--account",
      hostWalletName,
    ];

    const commandExternal = [
      "cast",
      "send",
      treasuryExternalChainAddress,
      "--rpc-url",
      externalChainRpcUrl,
      "_setHostChainAddress(address,string)",
      treasuryHostChainStationAddress,
      `"${getAddress(treasuryHostChainStationAddress)}"`,
      "--account",
      externalWalletName,
    ];
    console.log(
      `${colors.bright}→ Establishing connection: Host Station → External Station...${colors.reset}`
    );

    await $`${commandHost}`;

    console.log(
      `${colors.green}✓ Host Station → External Station: Connection established${colors.reset}\n`
    );

    console.log(
      `${colors.bright}→ Establishing connection: External Station → Host Station...${colors.reset}`
    );

    await $`${commandExternal}`;

    console.log(
      `${colors.green}✓ External Station → Host Station: Connection established${colors.reset}\n`
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
export async function walletIsSetup(
  walletName: string = "defaultKey"
): Promise<boolean> {
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
          contractAddress: getAddress(tx.contractAddress),
        } as CreatedContract)
    );

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}          Deployed Contracts${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  const chainData = ChainData[chainId];
  const explorerUrl = chainData?.ExplorerToAddress;

  createdContracts.forEach((contract: CreatedContract) => {
    console.log(
      `  ${colors.green}✓${colors.reset} ${colors.blue}${contract.contractName}${colors.reset}\n    ${colors.darkGray}→${colors.reset} ${contract.contractAddress}`
    );
    if (explorerUrl) {
      console.log(
        `    ${colors.darkGray}→${colors.reset} ${explorerUrl}${contract.contractAddress}`
      );
    }
  });
  console.log();

  return (
    createdContracts.find(
      (contract: CreatedContract) => contract.contractName === "Evvm"
    )?.contractAddress ?? null
  );
}

export async function showAllCrossChainDeployedContracts(
  chainIdHost: number,
  chainNameHost: string | undefined,
  chainIdExternal: number,
  chainNameExternal: string | undefined
): Promise<{
  evvmAddress: `0x${string}` | null;
  treasuryHostChainStationAddress: `0x${string}` | null;
  treasuryExternalChainStationAddress: `0x${string}` | null;
}> {
  const broadcastFileHost = `./broadcast/DeployCrossChainHost.s.sol/${chainIdHost}/run-latest.json`;
  const broadcastContentHost = await Bun.file(broadcastFileHost).text();
  const broadcastJsonHost = JSON.parse(broadcastContentHost);

  const broadcastFileExternal = `./broadcast/DeployCrossChainExternal.s.sol/${chainIdExternal}/run-latest.json`;
  const broadcastContentExternal = await Bun.file(broadcastFileExternal).text();
  const broadcastJsonExternal = JSON.parse(broadcastContentExternal);

  const createdContractsHost = broadcastJsonHost.transactions
    .filter((tx: any) => tx.transactionType === "CREATE")
    .map(
      (tx: any) =>
        ({
          contractName: tx.contractName,
          contractAddress: getAddress(tx.contractAddress),
        } as CreatedContract)
    );

  const createdContractsExternal = broadcastJsonExternal.transactions
    .filter((tx: any) => tx.transactionType === "CREATE")
    .map(
      (tx: any) =>
        ({
          contractName: tx.contractName,
          contractAddress: getAddress(tx.contractAddress),
        } as CreatedContract)
    );

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}          Deployed Contracts${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  if (chainNameHost) {
    console.log(
      `${colors.blue}Deployed on ${chainNameHost} (${colors.darkGray}${chainIdHost}${colors.reset})${colors.reset}`
    );
  } else {
    console.log(
      `${colors.blue}Deployed on Chain ID: ${colors.darkGray}${chainIdHost}${colors.reset}${colors.reset}`
    );
  }

  const chainDataHost = ChainData[chainIdHost];
  const explorerUrlHost = chainDataHost?.ExplorerToAddress;

  createdContractsHost.forEach((contract: CreatedContract) => {
    console.log(
      `  ${colors.green}✓${colors.reset} ${colors.blue}${contract.contractName}${colors.reset}\n    ${colors.darkGray}→${colors.reset} ${contract.contractAddress}`
    );
    if (explorerUrlHost) {
      console.log(
        `    ${colors.darkGray}→${colors.reset} ${explorerUrlHost}${contract.contractAddress}`
      );
    }
  });

  console.log();

  if (chainNameExternal) {
    console.log(
      `${colors.blue}Deployed on ${chainNameExternal} (${colors.darkGray}${chainIdExternal}${colors.reset})${colors.reset}`
    );
  } else {
    console.log(
      `${colors.blue}Deployed on Chain ID: ${colors.darkGray}${chainIdExternal}${colors.reset}${colors.reset}`
    );
  }

  const chainDataExternal = ChainData[chainIdExternal];
  const explorerUrlExternal = chainDataExternal?.ExplorerToAddress;

  createdContractsExternal.forEach((contract: CreatedContract) => {
    console.log(
      `  ${colors.green}✓${colors.reset} ${colors.blue}${contract.contractName}${colors.reset}\n    ${colors.darkGray}→${colors.reset} ${contract.contractAddress}`
    );
    if (explorerUrlExternal) {
      console.log(
        `    ${colors.darkGray}→${colors.reset} ${explorerUrlExternal}${contract.contractAddress}`
      );
    }
  });

  console.log();

  const evvmAddress =
    createdContractsHost.find(
      (contract: CreatedContract) => contract.contractName === "Evvm"
    )?.contractAddress ?? null;

  const treasuryHostChainStationAddress =
    createdContractsHost.find(
      (contract: CreatedContract) =>
        contract.contractName === "TreasuryHostChainStation"
    )?.contractAddress ?? null;

  const treasuryExternalChainStationAddress =
    createdContractsExternal.find(
      (contract: CreatedContract) =>
        contract.contractName === "TreasuryExternalChainStation"
    )?.contractAddress ?? null;

  return {
    evvmAddress,
    treasuryHostChainStationAddress,
    treasuryExternalChainStationAddress,
  };
}


/**
 * Generates Solidity interfaces for EVVM contracts
 *
 * Uses Foundry's `cast interface` command to create interface files for
 * all core EVVM contracts. Interfaces are saved in the `src/interfaces` directory.
 *
 * @returns {Promise<void>} Resolves when interfaces are generated
 */
export async function contractInterfacesGenerator() {
  let contracts: ContractFileMetadata[] = [
    {
      contractName: "Evvm",
      folderName: "evvm",
    },
    {
      contractName: "NameService",
      folderName: "nameService",
    },
    {
      contractName: "P2PSwap",
      folderName: "p2pSwap",
    },
    {
      contractName: "Staking",
      folderName: "staking",
    },
    {
      contractName: "Estimator",
      folderName: "staking",
    },
    {
      contractName: "Treasury",
      folderName: "treasury",
    },
    {
      contractName: "TreasuryExternalChainStation",
      folderName: "treasuryTwoChains",
    },
    {
      contractName: "TreasuryHostChainStation",
      folderName: "treasuryTwoChains",
    },
  ];

  console.log(
    `\n${colors.bright}╔═══════════════════════════════════════════════════════════╗${colors.reset}`
  );
  console.log(
    `${colors.bright}║          Generating Contract Interfaces                   ║${colors.reset}`
  );
  console.log(
    `${colors.bright}╚═══════════════════════════════════════════════════════════╝${colors.reset}\n`
  );

  const fs = require("fs");
  const path = "./src/interfaces";
  if (!fs.existsSync(path)) {
    console.log(
      `${colors.yellow}⚠  Interfaces folder not found. Creating...${colors.reset}\n`
    );
    fs.mkdirSync(path);
  }

  for (const contract of contracts) {
    console.log(
      `${colors.blue}▸ Processing ${contract.contractName}...${colors.reset}`
    );

    let evvmInterface =
      await $`cast interface src/contracts/${contract.folderName}/${contract.contractName}.sol`.quiet();
    let interfacePath = `./src/interfaces/I${contract.contractName}.sol`;

    // Process and clean the interface content
    let content = evvmInterface.stdout
      .toString()
      .replace(
        /^\/\/ SPDX-License-Identifier:.*$/m,
        "// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0\n// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense"
      )
      .replace("pragma solidity ^0.8.4;", "pragma solidity ^0.8.0;")
      .replace(
        `interface ${contract.contractName} {`,
        `interface I${contract.contractName} {`
      );

    fs.writeFileSync(interfacePath, content);

    console.log(
      `  ${colors.green}✓ I${contract.contractName}.sol${colors.reset} ${colors.darkGray}→ ${interfacePath}${colors.reset}\n`
    );
  }

  console.log(
    `${colors.green}✓${colors.reset}${colors.bright} Successfully generated ${contracts.length} interfaces${colors.reset}`
  );
}
