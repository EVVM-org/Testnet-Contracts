#!/usr/bin/env bun

/**
 * EVVM CLI Entry Point
 * 
 * Main command-line interface for EVVM contract deployment, registration,
 * and cross-chain configuration. Provides an interactive wizard-based workflow
 * with validation, error handling, and integration with Foundry tooling.
 * 
 * Supported operations:
 * - Single-chain and cross-chain EVVM deployment
 * - EVVM Registry registration on Ethereum Sepolia
 * - Cross-chain treasury station connection
 * - Developer utilities (interface generation, testing)
 * 
 * @module cli/index
 */

import { parseArgs } from "util";
import { colors } from "./constants";
import {
  register,
  showHelp,
  showVersion,
} from "./commands";
import { developer } from "./commands/developer";
import { setUpCrossChainTreasuries } from "./commands/setUpCrossChainTreasuries";
import { deploy } from "./commands/deploy";

/**
 * Available CLI commands mapped to their handler functions
 * 
 * @constant {Object} commands - Command name to handler function mapping
 * @property {Function} help - Display CLI help and usage information
 * @property {Function} version - Display CLI version number
 * @property {Function} deploy - Deploy EVVM contracts (single or cross-chain)
 * @property {Function} register - Register EVVM in registry (single or cross-chain)
 * @property {Function} setUpCrossChainTreasuries - Connect host and external treasury stations
 * @property {Function} dev - Developer utilities and tooling
 */
const commands = {
  help: showHelp,
  version: showVersion,
  deploy: deploy,
  register: register,
  setUpCrossChainTreasuries: setUpCrossChainTreasuries,
  dev: developer,
};

/**
 * Main CLI execution function
 * 
 * Orchestrates the CLI workflow:
 * 1. Parses command-line arguments using Node's util.parseArgs
 * 2. Handles global flags (--help, --version)
 * 3. Routes to appropriate command handler
 * 4. Provides error handling for unknown commands
 * 
 * Supported global flags:
 * - --help, -h: Display comprehensive help information
 * - --version, -v: Display CLI version number
 * - --verbose: Enable verbose logging (reserved for future use)
 * 
 * Command-specific options are passed through to individual handlers.
 * 
 * @returns {Promise<void>}
 * @throws {Error} When an unknown command is provided (exits with code 1)
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    showHelp();
    return;
  }

  /**
   * Parse command-line arguments with comprehensive option definitions
   * 
   * Global options:
   * - help, version: Display help or version information
   * - verbose: Enable verbose output (reserved for future use)
   * - crossChain: Enable cross-chain deployment/registration mode
   * 
   * Deployment options:
   * - skipInputConfig: Use configuration files instead of interactive prompts
   * - walletName/walletNameHost/walletNameExternal: Foundry wallet account names
   * 
   * Registration options:
   * - evvmAddress: Address of deployed EVVM contract
   * - useCustomEthRpc: Use custom Ethereum Sepolia RPC for registry calls
   * 
   * Cross-chain setup options:
   * - treasuryHostStationAddress: Host chain treasury station address
   * - treasuryExternalStationAddress: External chain treasury station address
   * 
   * Developer options:
   * - makeInterface: Generate Solidity interfaces from contracts
   */
  const { values, positionals } = parseArgs({
    args,
    options: {
      // general options
      help: { type: "boolean", short: "h" },
      version: { type: "boolean", short: "v" },
      verbose: { type: "boolean" },
      crossChain: { type: "boolean", short: "c" },
      
      // general deploy command options
      skipInputConfig: { type: "boolean", short: "s" },
      walletName: { type: "string", short: "n" },

      // setUpCrossChainTreasuries command specific
      treasuryHostStationAddress: { type: "string"},
      treasuryExternalStationAddress: { type: "string"},
      walletNameHost: { type: "string"},
      walletNameExternal: { type: "string"},

      // register command specific
      evvmAddress: { type: "string" },
      useCustomEthRpc: { type: "boolean" },

      //dev command specific
      makeInterface: { type: "boolean", short: "i"},
    },
    allowPositionals: true,
  });


  // Global flags
  if (values.help) {
    showHelp();
    return;
  }

  if (values.version) {
    showVersion();
    return;
  }

  // Execute command
  const command = positionals[0];
  const handler = commands[command as keyof typeof commands];

  if (handler) {
    await handler(positionals.slice(1), values);
  } else {
    console.error(
      `${colors.red}Error: Unknown command "${command}"${colors.reset}`
    );
    console.log(
      `Use ${colors.bright}--help${colors.reset} to see available commands\n`
    );
    process.exit(1);
  }
}

// Global error handling
process.on("uncaughtException", (error) => {
  console.error(`${colors.red}Fatal error:${colors.reset}`, error.message);
  process.exit(1);
});

// Execute
main().catch((error) => {
  console.error(`${colors.red}Error:${colors.reset}`, error.message);
  process.exit(1);
});
