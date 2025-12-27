/**
 * Cross-Chain Treasury Connection Command
 *
 * Establishes bidirectional communication between host and external chain
 * treasury stations for cross-chain asset management in EVVM deployments.
 *
 * @module cli/commands/setUpCrossChainTreasuries
 */

import { colors } from "../constants";
import { promptAddress } from "../utils/prompts";
import {
  callConnectStations,
  isChainIdRegistered,
  verifyFoundryInstalledAndAccountSetup,
} from "../utils/foundry";
import { chainIdNotSupported } from "../utils/outputMesages";
import { getRPCUrlAndChainId } from "../utils/rpc";

/**
 * Connects host and external chain treasury stations for cross-chain operations
 *
 * This command establishes the communication link between TreasuryHostChainStation
 * and TreasuryExternalChainStation contracts, enabling cross-chain asset transfers
 * and liquidity management across the EVVM deployment.
 * 
 * Process:
 * 1. Validates Foundry installation and both wallet accounts
 * 2. Prompts for treasury station addresses if not provided
 * 3. Validates both host and external chain IDs are supported
 * 4. Calls connectStations on both contracts to establish bidirectional link
 *
 * @param {string[]} _args - Command arguments (unused)
 * @param {any} options - Command options including:
 *   - treasuryHostStationAddress: Address of host chain station contract
 *   - treasuryExternalStationAddress: Address of external chain station contract
 *   - walletNameHost: Wallet name for host chain (default: "defaultKey")
 *   - walletNameExternal: Wallet name for external chain (default: "defaultKey")
 * @returns {Promise<void>}
 */
export async function setUpCrossChainTreasuries(_args: string[], options: any) {
  console.log(
    `${colors.bright}Connecting cross-chain treasury stations...${colors.reset}\n`
  );

  // --treasuryHostStationAddress
  let treasuryHostStationAddress: `0x${string}` | undefined =
    options.treasuryHostStationAddress;
  // --treasuryExternalStationAddress
  let treasuryExternalStationAddress: `0x${string}` | undefined =
    options.treasuryExternalStationAddress;
  // --walletNameHost
  let walletNameHost: string = options.walletNameHost || "defaultKey";
  // --walletNameExternal
  let walletNameExternal: string = options.walletNameExternal || "defaultKey";

  await verifyFoundryInstalledAndAccountSetup([
    walletNameHost,
    walletNameExternal,
  ]);

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

  if (!(await isChainIdRegistered(Number(hostChainId))))
    chainIdNotSupported(Number(hostChainId));

  if (!(await isChainIdRegistered(Number(externalChainId))))
    chainIdNotSupported(Number(externalChainId));

  console.log(`${colors.blue}Setting conections...${colors.reset}\n`);

  await callConnectStations(
    treasuryHostStationAddress as string,
    hostRPC,
    walletNameHost,
    treasuryExternalStationAddress as string,
    externalRPC,
    walletNameExternal
  );

  console.log(
    `${colors.darkGray}\nYour Treasury contracts are now connected!${colors.reset}\n`
  );
}
