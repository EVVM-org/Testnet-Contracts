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
import { showError } from "../../utils/validators";
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
export async function registerCross(_args: string[], options: any) {
  console.log(`${colors.bright}Starting EVVM registration...${colors.reset}\n`);

  // Get values from optional flags
  let evvmAddress: `0x${string}` | undefined = options.evvmAddress;
  let treasuryExternalStationAddress: `0x${string}` | undefined =
    options.treasuryExternalStationAddress;
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

  if (!(await verifyFoundryInstalledAndAccountSetup(walletName))) {
    return;
  }

  // Validate or prompt for missing values
  evvmAddress ||= promptAddress(
    `${colors.yellow}Enter the EVVM Address:${colors.reset}`
  );

  treasuryExternalStationAddress ||= promptAddress(
    `${colors.yellow}Enter the Treasury External Station Address:${colors.reset}`
  );

  let { rpcUrl: hostRpcUrl, chainId: hostChainId } = await getRPCUrlAndChainId(
    process.env.HOST_RPC_URL
  );
  let { rpcUrl: externalRpcUrl, chainId: externalChainId } =
    await getRPCUrlAndChainId(process.env.EXTERNAL_RPC_URL);

  if (hostChainId === 31337 || hostChainId === 1337) {
    console.log(
      `${colors.orange}Local blockchain detected - skipping registry registration${colors.reset}`
    );
    return;
  }

  const isSupported = await isChainIdRegistered(hostChainId);
  if (isSupported === undefined) {
    showError(
      `EVVM registration failed.`,
      `Please try again or if the issue persists, make an issue on GitHub.`
    );
    return;
  }
  if (!isSupported) {
    showError(
      `Host Chain ID ${hostChainId} is not supported.`,
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

  const evvmID: number | undefined = await callRegisterEvvm(
    Number(hostChainId),
    evvmAddress,
    walletName,
    ethRPC
  );
  if (!evvmID) {
    showError("EVVM registration failed.");
    return;
  }
  console.log(
    `${colors.green}Generated EVVM ID: ${colors.bright}${evvmID}${colors.reset}\n`
  );

  if (
    !(await callSetEvvmID(
      evvmAddress as `0x${string}`,
      evvmID,
      hostRpcUrl,
      walletName
    ))
  ) {
    showError(`Failed to set EVVM ID on host chain.`);
  }

  if (
    !(await callSetEvvmID(
      treasuryExternalStationAddress as `0x${string}`,
      evvmID,
      externalRpcUrl,
      walletName
    ))
  ) {
    showError("Failed to set EVVM ID on external chain.");
    return;
  }

  console.log(`\n${colors.bright}Registration complete${colors.reset}\n`);
  console.log(
    `${colors.green}EVVM ID:  ${colors.bright}${evvmID}${colors.reset}`
  );
  console.log(`${colors.green}Contract: ${evvmAddress}${colors.reset}`);
  console.log(
    `${colors.darkGray}\nYour EVVM instance is ready to use.${colors.reset}\n`
  );
}
