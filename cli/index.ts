#!/usr/bin/env bun

/**
 * EVVM CLI Entry Point
 * 
 * This module serves as the main entry point for the EVVM command-line interface.
 * It handles command parsing, routing, and global error handling for all CLI operations.
 * 
 * @module cli/index
 */

import { parseArgs } from "util";
import { colors } from "./constants";
import {
  showHelp,
  showVersion,
  deployEvvm,
  install,
  registerEvvm,
} from "./commands";

/**
 * Available CLI commands mapped to their handler functions
 */
const commands = {
  help: showHelp,
  version: showVersion,
  deploy: deployEvvm,
  install: install,
  register: registerEvvm,
};

/**
 * Main CLI execution function
 * 
 * Parses command-line arguments and routes to the appropriate command handler.
 * Handles global flags like --help and --version before delegating to specific commands.
 * 
 * @throws {Error} When an unknown command is provided
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0) {
    showHelp();
    return;
  }

  /**
   * Parse command-line arguments with supported options:
   * - help, version: Display help or version information
   * - skipInputConfig: Skip interactive configuration during deployment
   * - walletName: Specify Foundry wallet name for transactions
   * - evvmAddress: EVVM contract address for registration
   * - useCustomEthRpc: Use custom Ethereum Sepolia RPC for registry calls
   */
  const { values, positionals } = parseArgs({
    args,
    options: {
      help: { type: "boolean", short: "h" },
      version: { type: "boolean", short: "v" },
      name: { type: "string", short: "n" },
      verbose: { type: "boolean" },
      skipInputConfig: { type: "boolean", short: "s" },
      walletName: { type: "string", short: "w" },
      evvmAddress: { type: "string" },
      useCustomEthRpc: { type: "boolean" },
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
