/**
 * Help Command Module
 * 
 * Displays comprehensive CLI usage information including available commands,
 * options, and examples.
 * 
 * @module cli/commands/help
 */

import { colors } from "../constants";
import { version } from "../../package.json";

/**
 * Displays the CLI help message with all available commands and options
 * 
 * Outputs a formatted help screen including:
 * - Command descriptions and usage
 * - Available options and flags
 * - Example command invocations
 * - Links to documentation and support
 */
export function showHelp() {
  console.log(`
${colors.evvmGreen}╔═══════════════════════════════════════════════════════════╗
║                     EVVM CLI Tool v${version}                    ║
╚═══════════════════════════════════════════════════════════╝${colors.reset}

${colors.bright}USAGE:${colors.reset}
  ${colors.blue}evvm${colors.reset} ${colors.yellow}<command>${colors.reset} ${colors.darkGray}[options]${colors.reset}

${colors.bright}COMMANDS:${colors.reset}
  ${colors.green}deploy${colors.reset}              Deploy a new EVVM instance
                      ${colors.darkGray}Interactive wizard or use existing inputs (-s)${colors.reset}

  ${colors.green}register${colors.reset}            Register an EVVM instance with the registry
                      ${colors.darkGray}Supports single- and cross-chain registration${colors.reset}

  ${colors.green}setUpCrossChainTreasuries${colors.reset}
                      Configure cross-chain treasury stations (host ↔ external)

  ${colors.green}fulltest${colors.reset}            Run the complete test suite

  ${colors.green}developer${colors.reset}           Developer helpers and utilities

  ${colors.green}help${colors.reset}                Display this help message

  ${colors.green}version${colors.reset}             Show CLI version

${colors.bright}DEPLOY OPTIONS:${colors.reset}
  ${colors.yellow}--skipInputConfig${colors.reset}, ${colors.yellow}-s${colors.reset}
                      Skip interactive prompts and use existing ./input/BaseInputs.sol

  ${colors.yellow}--walletName${colors.reset} ${colors.darkGray}<name>${colors.reset}
                      Wallet name imported with cast (default: defaultKey)

  ${colors.yellow}--crossChain${colors.reset}, ${colors.yellow}-c${colors.reset}
                      Deploy a cross-chain EVVM instance

  ${colors.darkGray}Tip: Import keys securely with ${colors.bright}cast wallet import <name> --interactive${colors.reset}
  ${colors.darkGray}      Never store private keys in .env${colors.reset}

${colors.bright}REGISTER OPTIONS:${colors.reset}
  ${colors.yellow}--evvmAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
                      EVVM contract address to register

  ${colors.yellow}--walletName${colors.reset} ${colors.darkGray}<name>${colors.reset}
                      Wallet name for registry transactions

  ${colors.yellow}--useCustomEthRpc${colors.reset}
                      Use a custom Ethereum Sepolia RPC for registry calls
                      ${colors.darkGray}Reads EVVM_REGISTRATION_RPC_URL from .env or prompts if missing${colors.reset}

  ${colors.yellow}--crossChain${colors.reset}, ${colors.yellow}-c${colors.reset}
                      Register a cross-chain EVVM (uses cross-chain registration flow)

${colors.bright}SETUP CROSS-CHAIN OPTIONS:${colors.reset}
  ${colors.yellow}--treasuryHostStationAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
  ${colors.yellow}--treasuryExternalStationAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
  ${colors.yellow}--walletNameHost${colors.reset} ${colors.darkGray}<name>${colors.reset}
  ${colors.yellow}--walletNameExternal${colors.reset} ${colors.darkGray}<name>${colors.reset}
                      Configure treasury station connections between chains

${colors.bright}GLOBAL OPTIONS:${colors.reset}
  ${colors.yellow}-h${colors.reset}, ${colors.yellow}--help${colors.reset}          Show help
  ${colors.yellow}-v${colors.reset}, ${colors.yellow}--version${colors.reset}       Show version

${colors.bright}EXAMPLES:${colors.reset}
  ${colors.darkGray}# Deploy with interactive configuration${colors.reset}
  ${colors.blue}evvm deploy${colors.reset}

  ${colors.darkGray}# Deploy using existing config${colors.reset}
  ${colors.blue}evvm deploy --skipInputConfig${colors.reset}

  ${colors.darkGray}# Cross-chain deploy${colors.reset}
  ${colors.blue}evvm deploy --crossChain${colors.reset}

  ${colors.darkGray}# Configure cross-chain treasuries${colors.reset}
  ${colors.blue}evvm setUpCrossChainTreasuries --treasuryHostStationAddress <host> --treasuryExternalStationAddress <external> --walletNameHost <name> --walletNameExternal <name>${colors.reset}

  ${colors.darkGray}# Register cross-chain EVVM${colors.reset}
  ${colors.blue}evvm register --crossChain --evvmAddress 0x123... --walletName myWallet --useCustomEthRpc${colors.reset}

  ${colors.darkGray}# Import wallet securely (recommended)${colors.reset}
  ${colors.blue}cast wallet import defaultKey --interactive${colors.reset}

${colors.bright}DOCUMENTATION:${colors.reset}
  ${colors.blue}https://www.evvm.info/${colors.reset}

${colors.bright}SUPPORT:${colors.reset}
  ${colors.blue}https://github.com/EVVM-org/Testnet-Contracts/issues${colors.reset}
  `);
}