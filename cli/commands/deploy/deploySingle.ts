/**
 * EVVM Deployment Command
 *
 * Comprehensive deployment wizard for EVVM ecosystem contracts.
 * Handles configuration, validation, deployment, verification, and registration.
 *
 * @module cli/commands/deploy
 */

import { ChainData, colors } from "../../constants";
import { promptYesNo } from "../../utils/prompts";
import {
  forgeScript,
  isChainIdRegistered,
  showDeployContractsAndFindEvvm,
  verifyFoundryInstalledAndAccountSetup,
} from "../../utils/foundry";
import { getRPCUrlAndChainId } from "../../utils/rpc";
import { explorerVerification } from "../../utils/explorerVerification";
import { configurationBasic } from "../../utils/configurationInputs";
import { registerSingle } from "../register/registerSingle";
import {
  chainIdNotSupported,
  criticalError,
  showEvvmLogo,
} from "../../utils/outputMesages";

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
  // --skipInputConfig -s
  const skipInputConfig = options.skipInputConfig || false;
  // --walletName -n
  const walletName = options.walletName || "defaultKey";

  let verificationflag: string | undefined = "";

  // Banner
  showEvvmLogo();

  await verifyFoundryInstalledAndAccountSetup([walletName]);

  if (skipInputConfig) {
    console.log(
      `${colors.yellow}⚡ Skipping input configuration (using from ./input/BaseInputs.sol)...${colors.reset}\n`
    );
  } else {
    await configurationBasic();

    if (
      promptYesNo(
        `${colors.yellow}Proceed with deployment? (y/n):${colors.reset}`
      ).toLowerCase() !== "y"
    ) {
      console.log(`\n${colors.red}Deployment cancelled${colors.reset}`);
      return;
    }
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
    
    if (!(await isChainIdRegistered(chainId))) chainIdNotSupported(chainId);

    verificationflag = await explorerVerification();

    if (verificationflag === undefined)
      criticalError(`Explorer verification setup failed.`);
  }

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}             Deployment${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  console.log(
    ChainData[chainId]?.Chain
      ? `${colors.blue} Deploying on ${ChainData[chainId].Chain} (${colors.darkGray}${chainId})${colors.reset}`
      : `${colors.blue} Deploying on Chain ID:${colors.reset} ${chainId}`
  );

  await forgeScript(
    "script/Deploy.s.sol:DeployScript",
    rpcUrl,
    walletName,
    verificationflag ? verificationflag.split(" ") : []
  );

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
    `   ${colors.evvmGreen}evvm register --evvmAddress ${evvmAddress} --walletName <walletName>${colors.reset}`
  );
  console.log("Or if you want to use your custom Ethereum Sepolia RPC:");
  console.log(
    `   ${colors.evvmGreen}evvm register --evvmAddress ${evvmAddress} --walletName <walletName> --useCustomEthRpc${colors.reset}`
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
