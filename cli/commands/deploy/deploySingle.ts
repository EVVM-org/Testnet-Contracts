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
import {
  promptYesNo,
} from "../../utils/prompts";
import { showError } from "../../utils/validators";
import {
  isChainIdRegistered,
  showDeployContractsAndFindEvvm,
  verifyFoundryInstalledAndAccountSetup,
} from "../../utils/foundry";
import { getRPCUrlAndChainId } from "../../utils/rpc";
import { explorerVerification } from "../../utils/explorerVerification";
import { configurationBasic } from "../../utils/configurationInputs";
import { register } from "module";
import { registerSingle } from "../register/registerSingle";

/**
 * Deploys a complete EVVM instance with interactive configuration
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
export async function deploySingle(args: string[], options: any) {
  const skipInputConfig = options.skipInputConfig || false;
  const walletName = options.walletName || "defaultKey";

  let confirmationDone: boolean = false;

  let verificationflag: string | undefined = "";

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
      `${colors.yellow}⚡ Skipping input configuration (using from ./input/BaseInputs.sol)...${colors.reset}\n`
    );
  } else {
    if (!await configurationBasic()) return;
  }

  if (
    promptYesNo(
      `${colors.yellow}Proceed with deployment? (y/n):${colors.reset}`
    ).toLowerCase() !== "y"
  ) {
    console.log(`\n${colors.red}✗ Deployment cancelled${colors.reset}`);
    return;
  }

  const { rpcUrl, chainId } = await getRPCUrlAndChainId(process.env.RPC_URL);

  if (chainId === 31337 || chainId === 1337) {
    console.log(
      `\n${colors.orange}Local blockchain detected (Chain ID: ${chainId})${colors.reset}`
    );
    console.log(
      `${colors.darkGray}   Skipping host chain verification for local development${colors.reset}\n`
    );
  } else {
    const isSupported = await isChainIdRegistered(chainId);

    if (isSupported === undefined) {
      showError(
        `Chain ID ${chainId} is not supported.`,
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
    EVVM currently does not support mainnet deployments, do it manually at you own risk.
    
  ${colors.bright}• Local blockchains (Anvil/Hardhat):${colors.reset}
    Use an unregistered chain ID.
    ${colors.darkGray}Example: Chain ID 31337 is registered, use 1337 instead.${colors.reset}`
      );
      return;
    }

    verificationflag = await explorerVerification();
    if (verificationflag === undefined) {
      showError(
        `Explorer verification setup failed.`,
        `Please try again or if the issue persists, make an issue on GitHub.`
      );
      return;
    }
  }

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}             Deployment${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  const chainData = ChainData[chainId];

  // si encuentra el dato solo muestra deploying on ${ChainData.Chain} si no solo ${colors.blue} Chain ID:${colors.reset} ${chainId}
  if (chainData)
    console.log(
      `${colors.blue} Deploying on ${chainData.Chain}  (${colors.darkGray}${chainId})${colors.reset}`
    );
  else
    console.log(
      `${colors.blue} Deploying on Chain ID:${colors.reset} ${chainId}`
    );

  console.log(`${colors.evvmGreen}Starting deployment...${colors.reset}\n`);
  try {
    await $`forge clean`.quiet();

    // Split verification flags into array to avoid treating them as a single argument
    const verificationArgs = verificationflag
      ? verificationflag.split(" ")
      : [];
    const command = [
      "forge",
      "script",
      "script/Deploy.s.sol:DeployScript",
      "--via-ir",
      "--optimize",
      "true",
      "--rpc-url",
      rpcUrl,
      "--account",
      "defaultKey",
      ...verificationArgs,
      "--broadcast",
      "-vvvv",
    ];

    await $`${command}`;
    console.log(
      `\n${colors.green}✓ Deployment completed successfully!${colors.reset}`
    );
  } catch (error) {
    showError(
      "Deployment process encountered an error.",
      "Please check the error message above for details."
    );
    return;
  }

  const evvmAddress: `0x${string}` | null =
    await showDeployContractsAndFindEvvm(chainId);

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}            Deployment Success${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  console.log(
    `${colors.green}✓ EVVM deployed successfully at: ${evvmAddress}${colors.reset}\n`
  );

  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(
    `${colors.bright}          Next Step: Registration${colors.reset}`
  );
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(
    `${colors.blue}Your EVVM instance is ready to be registered.${colors.reset}`
  );
  console.log();
  console.log(`${colors.yellow}Important:${colors.reset}`);
  console.log(
    `   To register now, your Admin address must match the ${walletName} wallet.`
  );
  console.log(
    `   ${colors.darkGray}Otherwise, you can register later using:${colors.reset}`
  );
  console.log(
    `   ${colors.evvmGreen}evvm register --evvmAddress ${evvmAddress} --walletName ${walletName}${colors.reset}`
  );
  console.log();
  console.log(
    `   ${colors.darkGray}📖 For more details, visit:${colors.reset}`
  );
  console.log(
    `   ${colors.blue}https://www.evvm.info/docs/QuickStart#7-register-in-registry-evvm${colors.reset}`
  );
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

  await registerSingle([], {
    evvmAddress: evvmAddress,
    walletName: walletName,
    useCustomEthRpc: ethRPCAns,
  });
}
