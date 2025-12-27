/**
 * Cross-Chain EVVM Registration Command
 *
 * Handles registration of cross-chain EVVM deployments in the EVVM Registry
 * contract on Ethereum Sepolia. Generates a unique EVVM ID and updates both
 * the host chain EVVM contract and external chain treasury station with the
 * assigned identifier.
 *
 * @module cli/commands/register/registerCross
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
 * Registers a cross-chain EVVM instance in the EVVM Registry
 *
 * This command interacts with the EVVM Registry contract on Ethereum Sepolia
 * to obtain a globally unique EVVM ID, then updates both the host chain EVVM
 * contract and the external chain treasury station contract with this identifier.
 * This ensures both components of the cross-chain deployment share the same ID.
 * 
 * Process:
 * 1. Validates Foundry installation and both wallet accounts
 * 2. Prompts for EVVM and treasury station addresses if not provided
 * 3. Validates both host and external chains are supported (skips for local chains)
 * 4. Calls EVVM Registry on Ethereum Sepolia to generate EVVM ID
 * 5. Updates host chain EVVM contract with assigned ID
 * 6. Updates external chain treasury station contract with same ID
 *
 * @param {string[]} _args - Command arguments (unused, reserved for future use)
 * @param {any} options - Command options:
 *   - evvmAddress: Address of deployed EVVM contract on host chain
 *   - treasuryExternalStationAddress: Address of treasury station on external chain
 *   - walletNameHost: Foundry wallet for host chain (default: "defaultKey")
 *   - walletNameExternal: Foundry wallet for external chain (default: "defaultKey")
 *   - useCustomEthRpc: Use custom Ethereum Sepolia RPC instead of public (default: false)
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
