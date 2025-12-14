/**
 * Version Command Module
 * 
 * Displays the current CLI version from package.json.
 * 
 * @module cli/commands/version
 */

import { version } from "../../package.json";

/**
 * Displays the current CLI version number
 * 
 * Reads version information from package.json and outputs it to the console.
 */
export function showVersion() {
  console.log(`v${version}`);
}
