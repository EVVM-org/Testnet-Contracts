/**
 * Install Command Module
 * 
 * Executes the complete EVVM dependency installation process.
 * 
 * @module cli/commands/install
 */

import { $ } from "bun";
import { colors } from "../constants";

/**
 * Runs the full EVVM dependency installation
 * 
 * Executes all necessary commands to install project dependencies.
 * 
 * @returns {Promise<void>} A promise that resolves when installation is complete
 */
export async function install() {
  console.log(
    `${colors.evvmGreen}Starting installation of dependencies...${colors.reset}`
  );
  await $`bun install`;
  await $`forge install`;
  console.log(
    `${colors.evvmGreen}Dependencies installed successfully.${colors.reset}`
  );
}
