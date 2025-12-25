/**
 * EVVM Deployment Command
 *
 * Comprehensive deployment wizard for EVVM ecosystem contracts.
 * Handles configuration, validation, deployment, verification, and registration.
 *
 * @module cli/commands/deploy
 */

import { $ } from "bun";
import { ChainData, colors } from "../../constants";
import { promptYesNo } from "../../utils/prompts";
import { showError } from "../../utils/validators";
import {
  verifyFoundryInstalledAndAccountSetup,
  showAllCrossChainDeployedContracts,
} from "../../utils/foundry";
import { getRPCUrlAndChainId } from "../../utils/rpc";
import { explorerVerification } from "../../utils/explorerVerification";
import { setUpCrossChainTreasuries } from "../setUpCrossChainTreasuries";
import {
  configurationBasic,
  configurationCrossChain,
} from "../../utils/configurationInputs";
import { registerCross } from "../register/registerCross";

/**
 * Deploys a complete EVVM instance with interactive configuration for
 * cross-chain treasury support.
 *
 * Deployment process:
 * 1. Validates prerequisites (Foundry, wallet)
 * 2. Collects deployment configuration (addresses, metadata)
 * 3. Validates target chain support
 * 4. Configures block explorer verification
 * 5. Deploys all EVVM contracts
 * 6. Optionally registers EVVM in registry
 *
 * @param {string[]} args - Command arguments (unused)
 * @param {any} options - Command options including skipInputConfig, walletName
 * @returns {Promise<void>}
 */
export async function deployCross(args: string[], options: any) {
  const skipInputConfig = options.skipInputConfig || false;
  const walletName = options.walletName || "defaultKey";

  let externalRpcUrl: string | null = null;
  let externalChainId: number | null = null;
  let hostRpcUrl: string | null = null;
  let hostChainId: number | null = null;

  // Banner
  console.log(`${colors.evvmGreen}`);
  console.log("░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░  ");
  console.log("░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ");
  console.log("░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ");
  console.log("░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ");
  console.log("░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ");
  console.log("░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ");
  console.log("░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ");
  console.log(`${colors.reset}`);

  if (!(await verifyFoundryInstalledAndAccountSetup(walletName))) {
    return;
  }

  if (skipInputConfig) {
    console.log(
      `\n${colors.bright}Using Existing Configuration:${colors.reset}`
    );
    console.log(
      `  ${colors.green}✓${colors.reset} Base inputs ${colors.darkGray}→ ./input/BaseInputs.sol${colors.reset}`
    );
    console.log(
      `  ${colors.green}✓${colors.reset} Cross-chain inputs ${colors.darkGray}→ ./input/CrossChainInputs.sol${colors.reset}\n`
    );

    ({ rpcUrl: externalRpcUrl, chainId: externalChainId } =
      await getRPCUrlAndChainId(process.env.EXTERNAL_RPC_URL));
    ({ rpcUrl: hostRpcUrl, chainId: hostChainId } = await getRPCUrlAndChainId(
      process.env.HOST_RPC_URL
    ));
  } else {
    console.log(`\n${colors.bright}Base Configuration:${colors.reset}\n`);
    if (!(await configurationBasic())) return;
    console.log(
      `\n${colors.bright}Cross-Chain Configuration:${colors.reset}\n`
    );

    const ccConfig = await configurationCrossChain();
    if (typeof ccConfig === "boolean" && ccConfig === false) return;

    externalRpcUrl = ccConfig.externalRpcUrl;
    externalChainId = ccConfig.externalChainId;
    hostRpcUrl = ccConfig.hostRpcUrl;
    hostChainId = ccConfig.hostChainId;
  }

  if (!externalRpcUrl && !externalChainId && !hostRpcUrl && !hostChainId) {
    showError(
      "Failed to write inputs file.",
      `Please try again. If the issue persists, create an issue on GitHub:\n${colors.blue}https://github.com/EVVM-org/Playgrounnd-Contracts/issues${colors.reset}`
    );
    return;
  }

  if (
    promptYesNo(
      `${colors.yellow}Proceed with deployment? (y/n):${colors.reset}`
    ).toLowerCase() !== "y"
  ) {
    console.log(`\n${colors.red}✗ Deployment cancelled${colors.reset}`);
    return;
  }

  const verificationflagHost = await explorerVerification("Host Chain:");
  if (verificationflagHost === undefined) {
    showError("Explorer verification setup failed.");
    return;
  }

  const verificationflagExternal = await explorerVerification(
    "External Chain:"
  );
  if (verificationflagExternal === undefined) {
    showError("Explorer verification setup failed.");
    return;
  }

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}             Deployment${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  const chainDataExternal = ChainData[externalChainId!];

  if (chainDataExternal)
    console.log(
      `${colors.blue}Deploying on ${chainDataExternal.Chain}  ${colors.darkGray}(${externalChainId})${colors.reset}`
    );
  else
    console.log(
      `${colors.blue}Deploying on Chain ID:${colors.reset} ${externalChainId}`
    );
  console.log(
    `  ${colors.green}•${colors.reset} Treasury cross-chain contract  ${colors.darkGray}(TreasuryExternalChainStation.sol)${colors.reset}\n`
  );

  try {
    await $`forge clean`.quiet();

    // Split verification flags into array to avoid treating them as a single argument
    const verificationExternalArgs = verificationflagExternal
      ? verificationflagExternal.split(" ")
      : [];
    const commandExternal = [
      "forge",
      "script",
      "script/DeployCrossChainExternal.s.sol:DeployCrossChainExternalScript",
      "--via-ir",
      "--optimize",
      "true",
      "--rpc-url",
      externalRpcUrl,
      "--account",
      "defaultKey",
      ...verificationExternalArgs,
      "--broadcast",
      "-vvvv",
    ];
    await $`${commandExternal}`;
    console.log(
      `\n${colors.green}✓ Deployment on external chain completed successfully!${colors.reset}`
    );
  } catch (error) {
    showError(
      "Deployment process encountered an error.",
      "Please check the error message above for details."
    );
    return;
  }

  const chainDataHost = ChainData[hostChainId!];
  if (chainDataHost)
    console.log(
      `\n${colors.blue}Deploying on ${chainDataHost.Chain}  ${colors.darkGray}(${hostChainId})${colors.reset}`
    );
  else
    console.log(
      `\n${colors.blue}Deploying on Chain ID:${colors.reset} ${hostChainId}`
    );

  console.log(
    `  ${colors.green}•${colors.reset} Treasury cross-chain contract ${colors.darkGray}(TreasuryHostChainStation.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} EVVM core contract ${colors.darkGray}(Evvm.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} Staking contract ${colors.darkGray}(Staking.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} Estimator contract ${colors.darkGray}(Estimator.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} Name Service contract ${colors.darkGray}(NameService.sol)${colors.reset}`
  );
  console.log(
    `  ${colors.green}•${colors.reset} P2P Swap service ${colors.darkGray}(P2PSwap.sol)${colors.reset}\n`
  );

  try {
    await $`forge clean`.quiet();

    // Split verification flags into array to avoid treating them as a single argument
    const verificationHostArgs = verificationflagHost
      ? verificationflagHost.split(" ")
      : [];
    const commandHost = [
      "forge",
      "script",
      "script/DeployCrossChainHost.s.sol:DeployCrossChainHostScript",
      "--via-ir",
      "--optimize",
      "true",
      "--rpc-url",
      hostRpcUrl,
      "--account",
      "defaultKey",
      ...verificationHostArgs,
      "--broadcast",
      "-vvvv",
    ];
    await $`${commandHost}`;
    console.log(
      `\n${colors.green}✓ Deployment on host chain completed successfully!${colors.reset}`
    );
  } catch (error) {
    showError(
      "Deployment process encountered an error.",
      "Please check the error message above for details."
    );
    return;
  }

  const {
    evvmAddress,
    treasuryHostChainStationAddress,
    treasuryExternalChainStationAddress,
  } = await showAllCrossChainDeployedContracts(
    hostChainId!,
    chainDataHost && chainDataHost.Chain ? chainDataHost.Chain : undefined,
    externalChainId!,
    chainDataExternal && chainDataExternal.Chain
      ? chainDataExternal.Chain
      : undefined
  );
  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(
    `${colors.bright}          Deployment Complete${colors.reset}`
  );
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  console.log(`${colors.green}EVVM:             ${evvmAddress}${colors.reset}`);
  console.log(`${colors.green}Host Station:     ${treasuryHostChainStationAddress}${colors.reset}`);
  console.log(`${colors.green}External Station: ${treasuryExternalChainStationAddress}${colors.reset}\n`);

  console.log(`${colors.yellow}⚠ Important:${colors.reset} Admin addresses on both chains must match wallet ${colors.bright}'${walletName}'${colors.reset}`);
  console.log(`${colors.darkGray}   → If not configured or mismatched: Skip setup and run commands manually later${colors.reset}`);
  console.log(`${colors.darkGray}   → If already matching: Proceed with setup now${colors.reset}\n`);

  console.log(`${colors.bright}Manual setup commands:${colors.reset}`);
  console.log(`${colors.darkGray}1. Cross-chain communication:${colors.reset}`);
  console.log(`   ${colors.evvmGreen}evvm setUpCrossChainTreasuries \\${colors.reset}`);
  console.log(`   ${colors.evvmGreen}  --treasuryHostStationAddress ${treasuryHostChainStationAddress} \\${colors.reset}`);
  console.log(`   ${colors.evvmGreen}  --treasuryExternalStationAddress ${treasuryExternalChainStationAddress} \\${colors.reset}`);
  console.log(`   ${colors.evvmGreen}  --walletNameHost <wallet> --walletNameExternal <wallet>${colors.reset}\n`);

  console.log(`${colors.darkGray}2. EVVM registration:${colors.reset}`);
  console.log(`   ${colors.evvmGreen}evvm registerCrossChain \\${colors.reset}`);
  console.log(`   ${colors.evvmGreen}  --evvmAddress ${evvmAddress} \\${colors.reset}`);
  console.log(`   ${colors.evvmGreen}  --treasuryExternalStationAddress ${treasuryExternalChainStationAddress} \\${colors.reset}`);
  console.log(`   ${colors.evvmGreen}  --walletName <wallet>${colors.reset}\n`);

  console.log(`${colors.darkGray}More info: ${colors.blue}https://www.evvm.info/docs/QuickStart#7-register-in-registry-evvm${colors.reset}\n`);
  
  if (
    promptYesNo(
      `${colors.yellow}Do you want to set up cross-chain communication now? (y/n):${colors.reset}`
    ).toLowerCase() !== "y"
  ) {
    console.log(
      `${colors.red}Setup skipped. You can complete setup later using the commands above.${colors.reset}`
    );
    return;
  }

  await setUpCrossChainTreasuries([], {
    treasuryHostStationAddress:
      treasuryHostChainStationAddress as `0x${string}`,
    treasuryExternalStationAddress:
      treasuryExternalChainStationAddress as `0x${string}`,
    walletNameHost: walletName,
    walletNameExternal: walletName,
  });

  console.log();
  if (
    promptYesNo(
      `${colors.yellow}Do you want to register the EVVM instance now? (y/n):${colors.reset}`
    ).toLowerCase() !== "y"
  ) {
    console.log(
      `${colors.red}Registration skipped. You can register later using the command above.${colors.reset}`
    );
    return;
  }

  // If user decides, add --useCustomEthRpc flag to the registerEvvm call
  const ethRPCAns =
    promptYesNo(
      `${colors.yellow}Use custom Ethereum Sepolia RPC for registry calls? (y/n):${colors.reset}`
    ).toLowerCase() === "y";

  await registerCross([], {
    evvmAddress: evvmAddress,
    treasuryExternalStationAddress: treasuryExternalChainStationAddress,
    walletName: walletName,
    useCustomEthRpc: ethRPCAns,
  });
}
