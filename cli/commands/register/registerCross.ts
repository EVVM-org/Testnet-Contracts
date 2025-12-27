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
export async function registerCross(_args: string[], options: any) {
  console.log(`${colors.bright}Starting EVVM registration...${colors.reset}\n`);

  // Get values from optional flags
  let evvmAddress: `0x${string}` | undefined = options.evvmAddress;
  let treasuryExternalStationAddress: `0x${string}` | undefined =
    options.treasuryExternalStationAddress;
  let walletNameHost: string = options.walletNameHost || "defaultKey";
  let walletNameExternal: string = options.walletNameExternal || "defaultKey";
  let useCustomEthRpc: boolean = options.useCustomEthRpc || false;

  let ethRPC: string | undefined;

  // If --useCustomEthRpc is present, look for EVVM_REGISTRATION_RPC_URL in .env or prompt user
  ethRPC = useCustomEthRpc
    ? process.env.EVVM_REGISTRATION_RPC_URL ||
      promptString(
        `${colors.yellow}Enter the custom Ethereum Sepolia RPC URL:${colors.reset}`
      )
    : EthSepoliaPublicRpc;

  await verifyFoundryInstalledAndAccountSetup([
    walletNameHost,
    walletNameExternal,
  ]);

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

  if (!(await isChainIdRegistered(hostChainId)))
    chainIdNotSupported(hostChainId);
  if (!(await isChainIdRegistered(externalChainId)))
    chainIdNotSupported(externalChainId);

  const evvmID: number | undefined = await callRegisterEvvm(
    Number(hostChainId),
    evvmAddress,
    walletNameHost,
    ethRPC
  );

  if (evvmID === undefined) {
    criticalError(
      `Failed to obtain EVVM ID for contract ${evvmAddress}.`
    );
  }
  console.log(
    `${colors.green}Generated EVVM ID: ${colors.bright}${evvmID}${colors.reset}\n`
  );

  await callSetEvvmID(
    evvmAddress as `0x${string}`,
    evvmID!,
    hostRpcUrl,
    walletNameHost
  );

  await callSetEvvmID(
    treasuryExternalStationAddress as `0x${string}`,
    evvmID!,
    externalRpcUrl,
    walletNameExternal
  );

  console.log(`\n${colors.bright}Registration complete${colors.reset}\n`);
  console.log(
    `${colors.green}EVVM ID:  ${colors.bright}${evvmID!}${colors.reset}`
  );
  console.log(`${colors.green}Contract: ${evvmAddress}${colors.reset}`);
  console.log(
    `${colors.darkGray}\nYour EVVM instance is ready to use.${colors.reset}\n`
  );
}
