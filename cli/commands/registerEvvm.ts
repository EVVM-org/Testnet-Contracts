/**
 * EVVM Registration Command
 * 
 * Handles registration of deployed EVVM instances in the EVVM Registry.
 * Performs chain validation, generates EVVM ID, and updates the contract.
 * 
 * @module cli/commands/registerEvvm
 */

import { colors, EthSepoliaPublicRpc } from "../constants";
import { promptAddress, promptString } from "../utils/prompts";
import {
  callRegisterEvvm,
  callSetEvvmID,
  isChainIdRegistered,
  verifyFoundryInstalledAndAccountSetup,
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
export async function registerEvvm(_args: string[], options: any) {
  console.log(
    `${colors.evvmGreen}Registering a new EVVM instance...${colors.reset}`
  );

  // Get values from optional flags
  let evvmAddress: `0x${string}` | undefined = options.evvmAddress;
  let walletName: string = options.walletName || "defaultKey";
  let useCustomEthRpc: boolean = options.useCustomEthRpc || false;

  let ethRPC: string | undefined;

  // If --useCustomEthRpc is present, look for EVVM_REGISTRATION_RPC_URL in .env or prompt user
  ethRPC = useCustomEthRpc
    ? process.env.EVVM_REGISTRATION_RPC_URL || promptString(
        `${colors.yellow}Enter the custom Ethereum Sepolia RPC URL:${colors.reset}`
      )
    : EthSepoliaPublicRpc;

  if (!(await verifyFoundryInstalledAndAccountSetup(walletName))) {
    return;
  }

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

  const isSupported = await isChainIdRegistered(chainId);
  if (isSupported === undefined) {
    showError(
      `EVVM registration failed.`,
      `Please try again or if the issue persists, make an issue on GitHub.`
    );
    return;
  }
  if (!isSupported) {
    showError(
      `Host Chain ID ${chainId} is not supported.`,
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
    showError(
      `EVVM registration failed.`,
      `Please try again or if the issue persists, make an issue on GitHub.`
    );
    return;
  }
  console.log(
    `${colors.green}EVVM ID generated: ${colors.bright}${evvmID}${colors.reset}`
  );
  console.log(`${colors.blue}Setting EVVM ID on contract...${colors.reset}\n`);

  const isSet = await callSetEvvmID(evvmAddress, evvmID, rpcUrl, walletName);

  if (!isSet) {
    showError(
      `EVVM ID setting failed.`,
      `\n${colors.yellow}You can try manually with:${colors.reset}\n${colors.blue}cast send ${evvmAddress} \\\n  --rpc-url ${rpcUrl} \\\n  "setEvvmID(uint256)" ${evvmID} \\\n  --account ${walletName}${colors.reset}`
    );
    return;
  }

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
