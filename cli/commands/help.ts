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
  ${colors.green}deploy${colors.reset}              Deploy a new EVVM instance to a blockchain
                      ${colors.darkGray}Includes configuration, deployment, and optional registration${colors.reset}

  ${colors.green}register${colors.reset}            Register an existing EVVM instance
                      ${colors.darkGray}Links your EVVM to the EVVM Registry${colors.reset}

  ${colors.green}install${colors.reset}             Install all project dependencies
                      ${colors.darkGray}Runs bun install and forge install${colors.reset}

  ${colors.green}help${colors.reset}                Display this help message

  ${colors.green}version${colors.reset}             Show CLI version

${colors.bright}DEPLOY OPTIONS:${colors.reset}
  ${colors.yellow}--skipInputConfig${colors.reset}, ${colors.yellow}-s${colors.reset}
                      Skip interactive configuration and use existing ./input/Inputs.sol
  
  ${colors.yellow}--walletName${colors.reset} ${colors.darkGray}<name>${colors.reset}
                      Specify wallet name for deployment (default: defaultKey)

  ${colors.darkGray}Note: RPC URL is read from RPC_URL in .env file${colors.reset}
  ${colors.darkGray}      If not found, you will be prompted to enter it${colors.reset}

${colors.bright}REGISTER OPTIONS:${colors.reset}
  ${colors.yellow}--evvmAddress${colors.reset} ${colors.darkGray}<address>${colors.reset}
                      EVVM contract address to register
  
  ${colors.yellow}--walletName${colors.reset} ${colors.darkGray}<name>${colors.reset}
                      Specify wallet name for registration (default: defaultKey)

  ${colors.yellow}--useCustomEthRpc${colors.reset}
                      Use custom Ethereum Sepolia RPC for registry contract calls
                      ${colors.darkGray}Read from ETH_SEPOLIA_RPC in .env or prompts if not found${colors.reset}
                      ${colors.darkGray}Default: Uses public RPC${colors.reset}

  ${colors.darkGray}Note: Host chain RPC URL is read from RPC_URL in .env file${colors.reset}
  ${colors.darkGray}      If not found, you will be prompted to enter it${colors.reset}

${colors.bright}GLOBAL OPTIONS:${colors.reset}
  ${colors.yellow}-h${colors.reset}, ${colors.yellow}--help${colors.reset}          Show help
  ${colors.yellow}-v${colors.reset}, ${colors.yellow}--version${colors.reset}       Show version

${colors.bright}EXAMPLES:${colors.reset}
  ${colors.darkGray}# Deploy with interactive configuration${colors.reset}
  ${colors.blue}evvm deploy${colors.reset}

  ${colors.darkGray}# Deploy using existing config${colors.reset}
  ${colors.blue}evvm deploy --skipInputConfig${colors.reset}

  ${colors.darkGray}# Register an EVVM instance${colors.reset}
  ${colors.blue}evvm register --evvmAddress 0x123...${colors.reset}

  ${colors.darkGray}# Register with custom wallet${colors.reset}
  ${colors.blue}evvm register --evvmAddress 0x123... --walletName myWallet${colors.reset}

  ${colors.darkGray}# Register with custom Ethereum Sepolia RPC${colors.reset}
  ${colors.blue}evvm register --evvmAddress 0x123... --useCustomEthRpc${colors.reset}

  ${colors.darkGray}# Install dependencies${colors.reset}
  ${colors.blue}evvm install${colors.reset}

${colors.bright}DOCUMENTATION:${colors.reset}
  ${colors.blue}https://www.evvm.info/docs${colors.reset}

${colors.bright}SUPPORT:${colors.reset}
  ${colors.blue}https://github.com/EVVM-org/Playgrounnd-Contracts/issues${colors.reset}
  `);
}
