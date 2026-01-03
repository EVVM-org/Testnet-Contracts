/**
 * Developer Utilities Command Module
 *
 * Provides development utilities for EVVM contributors including interface
 * generation, test execution, and other developer-focused tooling.
 *
 * @module cli/commands/developer
 */

import { $ } from "bun";
import { colors } from "../constants";
import { contractInterfacesGenerator, contractTesting } from "../utils/foundry";
import { promptSelect, promptString } from "../utils/prompts";
import { seccionTitle } from "../utils/outputMesages";

/**
 * Developer utilities command handler
 *
 * Executes various developer utilities based on provided flags:
 * - Interface generation: Creates Solidity interfaces from contract implementations
 * - Full test suite execution (to be implemented)
 * - Service-specific tests (fuzz and unit) (to be implemented)
 * - Individual unit tests (to be implemented)
 * - Individual fuzz tests (to be implemented)
 *
 * @param {string[]} _args - Command arguments (unused, reserved for future use)
 * @param {any} options - Command options:
 *   - makeInterface: Generate Solidity interfaces for contracts (default: false)
 * @returns {Promise<void>}
 */
export async function developer(_args: string[], options: any) {
  let makeInterface = options.makeInterface || false;
  let runTest = options.runTest || false;

  seccionTitle("Developer Utilities");

  if (!makeInterface && !runTest) {
    const action = await promptSelect("Select an action:", [
      "Generate Contract Interfaces",
      "Run Full Test Suite",
      // Future options can be added here
      "exit",
    ]);

    switch (action) {
      case "Generate Contract Interfaces":
        makeInterface = true;
        break;
      case "Run Full Test Suite":
        runTest = true;
        break;
      case "exit":
        console.log(
          `${colors.green}Exiting developer utilities.${colors.reset}`
        );
        process.exit(0);
      default:
        console.log(
          `${colors.red}Invalid selection. Exiting developer utilities.${colors.reset}`
        );
        process.exit(1);
    }
  }

  if (makeInterface) await contractInterfacesGenerator();
  if (runTest) await contractTesting();
}
