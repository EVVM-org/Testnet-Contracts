import { ChainData as ChainDataConstant, colors } from "../constants";
import type { ChainData } from "../types";
import { isChainIdRegistered } from "./foundry";
import { promptAddress, promptNumber, promptYesNo } from "./prompts";
import { showError } from "./validators";

export async function checkCrossChainSupport(
  chainId: number
): Promise<ChainData | undefined> {
  if (chainId === 31337 || chainId === 1337) {
    showError(
      `Local blockchain detected (Chain ID: ${chainId}).`,
      `Please use a testnet host chain for cross-chain deployments.`
    );
    return undefined;
  } else {
    const isSupported = await isChainIdRegistered(chainId);

    if (isSupported === undefined) {
      showError(
        `Chain ID ${chainId} is not supported.`,
        `Please try again or if the issue persists, make an issue on GitHub.`
      );
      return undefined;
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
      return undefined;
    }
  }

  const chainData = ChainDataConstant[chainId];

  if (!chainData) {
    showError(
      `No chain data found for Chain ID ${chainId}.`,
      `Please ensure the chain is supported and try again.`
    );
    return undefined;
  }

  let auxChainData = chainData;

  if (chainData.Hyperlane.MailboxAddress == "") {
    console.log(
      `\n${colors.red}✗ Hyperlane support not available${colors.reset} on ${colors.blue}${chainData.Chain}${colors.reset} ${colors.darkGray}(${chainId})${colors.reset}`
    );
    console.log(`  ${colors.darkGray}Check availability at:${colors.reset}`);
    console.log(
      `  ${colors.darkGray}→ ${colors.blue}https://docs.hyperlane.xyz/docs/reference/addresses/deployments/mailbox#testnet${colors.reset}\n`
    );

    if (
      promptYesNo(
        `${colors.yellow}Do you want to add Hyperlane data? (y/n):${colors.reset}`
      ) === "y"
    ) {
      auxChainData.Hyperlane.DomainId = promptNumber(
        `${colors.yellow}Enter Hyperlane Domain ID for ${chainData.Chain} (${chainId}):${colors.reset} `
      );
      auxChainData.Hyperlane.MailboxAddress = promptAddress(
        `${colors.yellow}Enter Hyperlane Mailbox Address for ${chainData.Chain} (${chainId}):${colors.reset} `
      );
    } else {
      if (
        promptYesNo(
          `${colors.yellow}Do you want to continue without adding Hyperlane data? (y/n):${colors.reset}`
        ) === "n"
      ) {
        return undefined;
      }
    }
  }
  if (chainData.LayerZero.EndpointAddress == "") {
    console.log(
      `\n${colors.red}✗ LayerZero support not available${colors.reset} on ${colors.blue}${chainData.Chain}${colors.reset} ${colors.darkGray}(${chainId})${colors.reset}`
    );
    console.log(`  ${colors.darkGray}Check availability at:${colors.reset}`);
    console.log(
      `  ${colors.darkGray}→ ${colors.blue}https://docs.layerzero.network/v2/deployments/deployed-contracts?stages=testnet${colors.reset}\n`
    );
    if (
      promptYesNo(
        `${colors.yellow}Do you want to add LayerZero data? (y/n):${colors.reset}`
      ) === "y"
    ) {
      auxChainData.LayerZero.EId = promptNumber(
        `${colors.yellow}Enter LayerZero EId for ${chainData.Chain} (${chainId}):${colors.reset} `
      );
      auxChainData.LayerZero.EndpointAddress = promptAddress(
        `${colors.yellow}Enter LayerZero Endpoint Address for ${chainData.Chain} (${chainId}):${colors.reset} `
      );
    } else {
      if (
        promptYesNo(
          `${colors.yellow}Do you want to continue without adding LayerZero data? (y/n):${colors.reset}`
        ) === "n"
      ) {
        return undefined;
      }
    }
  }
  if (chainData.Axelar.Gateway == "") {
    console.log(
      `\n${colors.red}✗ Axelar support not available${colors.reset} on ${colors.blue}${chainData.Chain}${colors.reset} ${colors.darkGray}(${chainId})${colors.reset}`
    );
    console.log(`  ${colors.darkGray}Check availability at:${colors.reset}`);
    console.log(
      `  ${colors.darkGray}→ ${colors.blue}https://axelarscan.io/resources/chains?type=evm${colors.reset}\n`
    );
    if (
      promptYesNo(
        `${colors.yellow}Do you want to add Axelar data? (y/n):${colors.reset}`
      ) === "y"
    ) {
      auxChainData.Axelar.ChainName = promptAddress(
        `${colors.yellow}Enter Axelar Chain Name for ${chainData.Chain} (${chainId}):${colors.reset} `
      );
      auxChainData.Axelar.Gateway = promptAddress(
        `${colors.yellow}Enter Axelar Gateway Address for ${chainData.Chain} (${chainId}):${colors.reset} `
      );
      auxChainData.Axelar.GasService = promptAddress(
        `${colors.yellow}Enter Axelar Gas Service Address for ${chainData.Chain} (${chainId}):${colors.reset} `
      );
    } else {
      if (
        promptYesNo(
          `${colors.yellow}Do you want to continue without adding Axelar data? (y/n):${colors.reset}`
        ) === "n"
      ) {
        return undefined;
      }
    }
  }

  if (
    chainData.Hyperlane.MailboxAddress == "" ||
    chainData.LayerZero.EndpointAddress == "" ||
    chainData.Axelar.Gateway == ""
  ) {
    console.log(
      `\n${colors.bright}Cross-Chain Configuration for ${colors.blue}${chainData.Chain}${colors.reset} ${colors.darkGray}(${chainId})${colors.reset}${colors.bright}:${colors.reset}\n`
    );
    console.log(
      `${colors.bright}Hyperlane:${colors.reset}
  ${colors.darkGray}→${colors.reset} Domain ID: ${colors.blue}${auxChainData.Hyperlane.DomainId}${colors.reset}
  ${colors.darkGray}→${colors.reset} Mailbox: ${colors.blue}${auxChainData.Hyperlane.MailboxAddress}${colors.reset}`
    );
    console.log(
      `\n${colors.bright}LayerZero:${colors.reset}
  ${colors.darkGray}→${colors.reset} EId: ${colors.blue}${auxChainData.LayerZero.EId}${colors.reset}
  ${colors.darkGray}→${colors.reset} Endpoint: ${colors.blue}${auxChainData.LayerZero.EndpointAddress}${colors.reset}`
    );
    console.log(
      `\n${colors.bright}Axelar:${colors.reset}
  ${colors.darkGray}→${colors.reset} Chain Name: ${colors.blue}${auxChainData.Axelar.ChainName}${colors.reset}
  ${colors.darkGray}→${colors.reset} Gateway: ${colors.blue}${auxChainData.Axelar.Gateway}${colors.reset}
  ${colors.darkGray}→${colors.reset} Gas Service: ${colors.blue}${auxChainData.Axelar.GasService}${colors.reset}`
    );
    console.log();

    if (
      promptYesNo(
        `${colors.yellow}Proceed with this configuration? (y/n):${colors.reset}`
      ) === "n"
    ) {
      return undefined;
    }
  }

  return auxChainData;
}
