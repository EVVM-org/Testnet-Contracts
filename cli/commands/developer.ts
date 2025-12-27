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
import { contractInterfacesGenerator } from "../utils/foundry";

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
  const makeInterface = options.makeInterface || false;

  if (makeInterface) await contractInterfacesGenerator();
}
