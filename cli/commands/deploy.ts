/**
 * EVVM Deployment Command
 * 
 * Comprehensive deployment wizard for EVVM ecosystem contracts.
 * Handles configuration, validation, deployment, verification, and registration.
 * 
 * @module cli/commands/deploy
 */

import { $ } from "bun";
import type { ConfirmAnswer, InputAddresses, EvvmMetadata } from "../types";
import { colors } from "../constants";
import {
  promptString,
  promptNumber,
  promptAddress,
  promptYesNo,
} from "../utils/prompts";
import { formatNumber, showError } from "../utils/validators";
import {
  writeInputsFile,
  isChainIdRegistered,
  showDeployContractsAndFindEvvm,
  verifyFoundryInstalledAndAccountSetup,
} from "../utils/foundry";
import { getRPCUrlAndChainId } from "../utils/rpc";
import { registerEvvm } from "./registerEvvm";
import { explorerVerification } from "../utils/explorerVerification";

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
export async function deployEvvm(args: string[], options: any) {
  const skipInputConfig = options.skipInputConfig || false;
  const walletName = options.walletName || "defaultKey";

  let isDeployingOnLocalBlockchain = false;

  let confirmAnswer: ConfirmAnswer = {
    configureAdvancedMetadata: "",
    confirmInputs: "",
    deploy: "",
    register: "",
    useCustomEthRpc: "",
  };

  let confirmationDone: boolean = false;

  let verificationflag: string | undefined = "";

  let evvmMetadata: EvvmMetadata = {
    EvvmName: "EVVM",
    EvvmID: 0,
    principalTokenName: "Mate Token",
    principalTokenSymbol: "MATE",
    principalTokenAddress: "0x0000000000000000000000000000000000000001",
    totalSupply: 2033333333000000000000000000,
    eraTokens: 1016666666500000000000000000,
    reward: 5000000000000000000,
  };

  let addresses: InputAddresses = {
    admin: null,
    goldenFisher: null,
    activator: null,
  };

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
      `${colors.yellow}⚡ Skipping input configuration (using from ./input/Inputs.sol)...${colors.reset}\n`
    );
  } else {
    while (!confirmationDone) {
      for (const key of Object.keys(addresses) as (keyof InputAddresses)[]) {
        addresses[key] = promptAddress(
          `${colors.yellow}Enter the ${key} address:${colors.reset}`
        );
      }

      evvmMetadata.EvvmName = promptString(
        `${colors.yellow}EVVM Name ${colors.darkGray}[${evvmMetadata.EvvmName}]:${colors.reset}`,
        evvmMetadata.EvvmName ?? undefined
      );

      evvmMetadata.principalTokenName = promptString(
        `${colors.yellow}Principal Token Name ${colors.darkGray}[${evvmMetadata.principalTokenName}]:${colors.reset}`,
        evvmMetadata.principalTokenName ?? undefined
      );

      evvmMetadata.principalTokenSymbol = promptString(
        `${colors.yellow}Principal Token Symbol ${colors.darkGray}[${evvmMetadata.principalTokenSymbol}]:${colors.reset}`,
        evvmMetadata.principalTokenSymbol ?? undefined
      );

      console.log();
      confirmAnswer.configureAdvancedMetadata = promptYesNo(
        `${colors.yellow}Configure advanced metadata (totalSupply, eraTokens, reward)? (y/n):${colors.reset}`
      );

      if (confirmAnswer.configureAdvancedMetadata.toLowerCase() === "y") {
        evvmMetadata.totalSupply = promptNumber(
          `${colors.yellow}Total Supply ${colors.darkGray}[${formatNumber(
            evvmMetadata.totalSupply
          )}]:${colors.reset}`,
          evvmMetadata.totalSupply ?? undefined
        );

        evvmMetadata.eraTokens = promptNumber(
          `${colors.yellow}Era Tokens ${colors.darkGray}[${formatNumber(
            evvmMetadata.eraTokens
          )}]:${colors.reset}`,
          evvmMetadata.eraTokens ?? undefined
        );

        evvmMetadata.reward = promptNumber(
          `${colors.yellow}Reward ${colors.darkGray}[${formatNumber(
            evvmMetadata.reward
          )}]:${colors.reset}`,
          evvmMetadata.reward ?? undefined
        );
      }

      console.log(
        `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
      );
      console.log(
        `${colors.bright}          Configuration Summary${colors.reset}`
      );
      console.log(
        `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
      );

      console.log(`${colors.bright}Addresses:${colors.reset}`);
      for (const key of Object.keys(addresses) as (keyof InputAddresses)[]) {
        console.log(`  ${colors.blue}${key}:${colors.reset} ${addresses[key]}`);
      }

      console.log(`\n${colors.bright}EVVM Metadata:${colors.reset}`);
      for (const [metaKey, metaValue] of Object.entries(evvmMetadata)) {
        if (metaKey === "EvvmID") continue;

        let displayValue = metaValue;
        if (typeof metaValue === "number" && metaValue > 1e15) {
          displayValue = metaValue.toLocaleString("fullwide", {
            useGrouping: false,
          });
        }
        console.log(
          `  ${colors.blue}${metaKey}:${colors.reset} ${displayValue}`
        );
      }
      console.log();

      confirmAnswer.confirmInputs = promptYesNo(
        `${colors.yellow}Confirm configuration? (y/n):${colors.reset}`
      );

      if (confirmAnswer.confirmInputs.toLowerCase() === "y") {
        confirmationDone = true;
      }
    }

    if (!(await writeInputsFile(addresses, evvmMetadata))) {
      showError(
        "Failed to write inputs file.",
        `Please try again. If the issue persists, create an issue on GitHub:\n${colors.blue}https://github.com/EVVM-org/Testnet-Contracts/issues${colors.reset}`
      );
      return;
    }

    console.log(`\n${colors.bright}Ready to Deploy${colors.reset}\n`);
    confirmAnswer.deploy = promptYesNo(
      `${colors.yellow}Proceed with deployment? (y/n):${colors.reset}`
    );

    if (confirmAnswer.deploy.toLowerCase() !== "y") {
      console.log(`\n${colors.red}✗ Deployment cancelled${colors.reset}`);
      return;
    }
  }

  const { rpcUrl, chainId } = await getRPCUrlAndChainId(process.env.RPC_URL);

  isDeployingOnLocalBlockchain = chainId === 31337 || chainId === 1337;

  if (isDeployingOnLocalBlockchain) {
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
        `Please try again. If the issue persists, create an issue on GitHub:\n${colors.blue}https://github.com/EVVM-org/Testnet-Contracts/issues${colors.reset}`
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

    verificationflag = await explorerVerification();
    if (verificationflag === undefined) {
      showError(
        `Explorer verification setup failed.`,
        `Please try again. If the issue persists, create an issue on GitHub:\n${colors.blue}https://github.com/EVVM-org/Testnet-Contracts/issues${colors.reset}`
      );
      return;
    }
  }

  const privateKey =
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";

  console.log(
    `\n${colors.bright}═══════════════════════════════════════${colors.reset}`
  );
  console.log(`${colors.bright}             Deployment${colors.reset}`);
  console.log(
    `${colors.bright}═══════════════════════════════════════${colors.reset}\n`
  );

  console.log(`${colors.blue} Chain ID:${colors.reset} ${chainId}`);
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
    `   To register now, your Admin address must match the defaultKey wallet.`
  );
  console.log(
    `   ${colors.darkGray}Otherwise, you can register later using:${colors.reset}`
  );
  console.log(
    `   ${colors.evvmGreen}evvm register --evvmAddress ${evvmAddress}${colors.reset}`
  );
  console.log();
  console.log(
    `   ${colors.darkGray}📖 For more details, visit:${colors.reset}`
  );
  console.log(
    `   ${colors.blue}https://www.evvm.info/docs/QuickStart#6-register-in-registry-evvm${colors.reset}`
  );
  console.log();

  confirmAnswer.register = promptYesNo(
    `${colors.yellow}Do you want to register the EVVM instance now? (y/n):${colors.reset}`
  );

  if (confirmAnswer.register.toLowerCase() !== "y") {
    console.log(
      `${colors.red}Registration skipped. You can register later using the command above.${colors.reset}`
    );
    return;
  }

  confirmAnswer.useCustomEthRpc = promptYesNo(
    `${colors.yellow}Do you want to use custom Ethereum Sepolia RPC for registry contract calls? (y/n):${colors.reset}`
  );
  // If user decides, add --useCustomEthRpc flag to the registerEvvm call
  const ethRPCAns =
    confirmAnswer.useCustomEthRpc.toLowerCase() === "y" ? true : false;
  

  registerEvvm([], {
    evvmAddress: evvmAddress,
    walletName: walletName,
    useCustomEthRpc: ethRPCAns,
  });
}



