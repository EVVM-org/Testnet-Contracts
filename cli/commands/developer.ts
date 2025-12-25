/**
 * Full Test Command Module
 *
 * Executes the complete EVVM test suite using Foundry's forge test.
 *
 * @module cli/commands/fulltest
 */

import { $ } from "bun";
import { colors } from "../constants";
import { contractInterfacesGenerator } from "../utils/foundry";

/**
 * Developer Command Handler
 *
 * Executes developer utilities such as:
 * - Generating Solidity interfaces for EVVM contracts
 * - Runing full test suite (to be implemented)
 * - Runing specific service tests (fuzz and unit) (to be implemented)
 * - Runing especific unit tests (to be implemented)
 * - Runing epecific fuzz tests (to be implemented)
 */
export async function developer(_args: string[], options: any) {
  const makeInterface = options.makeInterface || false;

  if (makeInterface) await contractInterfacesGenerator();
}
