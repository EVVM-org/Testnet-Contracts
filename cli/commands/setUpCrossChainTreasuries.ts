/**
 * EVVM Registration Command
 *
 * Handles registration of deployed EVVM instances in the EVVM Registry.
 * Performs chain validation, generates EVVM ID, and updates the contract.
 *
 * @module cli/commands/registerEvvm
 */

import { colors } from "../constants";
import { promptAddress } from "../utils/prompts";
import {
  callConnectStations,
  foundryIsInstalled,
  isChainIdRegistered,
  walletIsSetup,
} from "../utils/foundry";
import { showError } from "../utils/validators";
import { getRPCUrlAndChainId } from "../utils/rpc";

/**
 * Registers an EVVM instance in the registry contract
 *
 * Process:
 * 1. Validates Foundry installation and wallet setup
 * 2. Verifies EVVM address and host chain support
 * 3. Calls registry contract to obtain EVVM ID
 * 4. Updates EVVM contract with assigned ID
 *
 * @param {string[]} _args - Command arguments (unused)
 * @param {any} options - Command options including evvmAddress, walletName, useCustomEthRpc
 * @returns {Promise<void>}
 */
export async function setUpCrossChainTreasuries(_args: string[], options: any) {
  console.log(`${colors.bright}Connecting cross-chain treasury stations...${colors.reset}\n`);

  // Get values from optional flags
  let treasuryHostStationAddress: `0x${string}` | undefined =
    options.treasuryHostStationAddress;
  let treasuryExternalStationAddress: `0x${string}` | undefined =
    options.treasuryExternalStationAddress;
  let walletNameHost: string = options.walletNameHost || "defaultKey";
  let walletNameExternal: string = options.walletNameExternal || "defaultKey";

  if (!(await foundryIsInstalled())) {
    return showError(
      "Foundry is not installed.",
      "Please install Foundry to proceed with setup."
    );
  }

  for (const walletName of [walletNameHost, walletNameExternal]) {
    if (!(await walletIsSetup(walletName))) {
      return showError(
        `Wallet '${walletName}' is not available.`,
        `Please import your wallet using:\n   ${colors.evvmGreen}cast wallet import ${walletName} --interactive${colors.reset}\n\n   You'll be prompted to enter your private key securely.`
      );
    }
  }

  // Validate or prompt for missing values
  treasuryHostStationAddress ||= promptAddress(
    `${colors.yellow}Enter the Host Station Address:${colors.reset}`
  );

  treasuryExternalStationAddress ||= promptAddress(
    `${colors.yellow}Enter the External Station Address:${colors.reset}`
  );

  const { rpcUrl: hostRPC, chainId: hostChainId } = await getRPCUrlAndChainId(
    process.env.HOST_RPC_URL
  );
  const { rpcUrl: externalRPC, chainId: externalChainId } =
    await getRPCUrlAndChainId(process.env.EXTERNAL_RPC_URL);

  for (const [chainId, chainType] of [
    [hostChainId, "Host"],
    [externalChainId, "External"],
  ]) {
    if (chainId === undefined) {
      showError(
        `Invalid chain ID.`,
        `The chain ID for ${chainType} is undefined. Please check your RPC URL or configuration.`
      );
      return;
    }
    const isSupported = await isChainIdRegistered(Number(chainId));
    if (isSupported === undefined) {
      showError(
        `EVVM registration failed.`,
        `Please try again or if the issue persists, make an issue on GitHub.`
      );
      return;
    }
    if (!isSupported) {
      showError(
        `${chainType} Chain ID ${chainId} is not supported.`,
        `\n${colors.yellow}Possible solutions:${colors.reset}
  ${colors.bright}• Testnet chains:${colors.reset}
    Request support by creating an issue at:
    ${colors.blue}https://github.com/EVVM-org/evvm-registry-contracts${colors.reset}
    
  ${colors.bright}• Mainnet chains:${colors.reset}
    EVVM currently does not support mainnet deployments.
    
  ${colors.bright}• Local blockchains (Anvil/Hardhat):${colors.reset}
    Use an unregistered chain ID.
    ${colors.darkGray}Example: Chain ID 31337 is registered, use 1337 instead.${colors.reset}`
      );
      return;
    }
  }

  console.log(`${colors.blue}Setting conections...${colors.reset}\n`);

  const isSetOnHost = await callConnectStations(
    treasuryHostStationAddress as string,
    hostRPC,
    walletNameHost,
    treasuryExternalStationAddress as string,
    externalRPC,
    walletNameExternal
  );

  if (!isSetOnHost) {
    showError(
      `EVVM registration failed.`,
      `Please try again or if the issue persists, make an issue on GitHub.`
    );
    return;
  }
  console.log(
    `${colors.darkGray}\nYour Treasury contracts are now connected!${colors.reset}\n`
  );
}
