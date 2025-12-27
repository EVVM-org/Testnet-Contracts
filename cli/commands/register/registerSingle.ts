/**
 * EVVM Registration Command
 *
 * Handles registration of deployed EVVM instances in the EVVM Registry.
 * Performs chain validation, generates EVVM ID, and updates the contract.
 *
 * @module cli/commands/registerEvvm
 */

import { colors, EthSepoliaPublicRpc } from "../../constants";
import { promptAddress, promptString } from "../../utils/prompts";
import {
  callRegisterEvvm,
  callSetEvvmID,
  isChainIdRegistered,
  verifyFoundryInstalledAndAccountSetup,
} from "../../utils/foundry";
import { chainIdNotSupported, criticalError } from "../../utils/outputMesages";
import { getRPCUrlAndChainId } from "../../utils/rpc";

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
export async function registerSingle(_args: string[], options: any) {
  console.log(`${colors.bright}Starting EVVM registration...${colors.reset}\n`);

  // Get values from optional flags
  let evvmAddress: `0x${string}` | undefined = options.evvmAddress;
  let walletName: string = options.walletName || "defaultKey";
  let useCustomEthRpc: boolean = options.useCustomEthRpc || false;

  let ethRPC: string | undefined;

  // If --useCustomEthRpc is present, look for EVVM_REGISTRATION_RPC_URL in .env or prompt user
  ethRPC = useCustomEthRpc
    ? process.env.EVVM_REGISTRATION_RPC_URL ||
      promptString(
        `${colors.yellow}Enter the custom Ethereum Sepolia RPC URL:${colors.reset}`
      )
    : EthSepoliaPublicRpc;

  await verifyFoundryInstalledAndAccountSetup([walletName]);

  // Validate or prompt for missing values
  evvmAddress ||= promptAddress(
    `${colors.yellow}Enter the EVVM Address:${colors.reset}`
  );

  let { rpcUrl, chainId } = await getRPCUrlAndChainId(process.env.RPC_URL);

  if (chainId === 31337 || chainId === 1337) {
    console.log(`\n${colors.orange}Local Blockchain Detected${colors.reset}`);
    console.log(
      `${colors.darkGray}Skipping registry contract registration for local development${colors.reset}`
    );
    return;
  }

  if (!(await isChainIdRegistered(chainId))) chainIdNotSupported(chainId);

  console.log(
    `${colors.blue}Setting EVVM ID directly on contract...${colors.reset}\n`
  );

  const evvmID: number | undefined = await callRegisterEvvm(
    Number(chainId),
    evvmAddress,
    walletName,
    ethRPC
  );
  if (!evvmID) {
    criticalError(`Failed to obtain EVVM ID for contract ${evvmAddress}.`);
  }
  console.log(
    `${colors.green}EVVM ID generated: ${colors.bright}${evvmID}${colors.reset}`
  );
  console.log(`${colors.blue}Setting EVVM ID on contract...${colors.reset}\n`);

  await callSetEvvmID(evvmAddress, evvmID!, rpcUrl, walletName);

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}        Registration Complete${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );
  console.log(
    `${colors.green}EVVM ID: ${colors.bright}${evvmID}${colors.reset}`
  );
  console.log(
    `${colors.green}Contract: ${colors.bright}${evvmAddress}${colors.reset}`
  );
  console.log(
    `${colors.darkGray}\nYour EVVM instance is now ready to use!${colors.reset}\n`
  );
}
