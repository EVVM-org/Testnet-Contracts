/**
 * Validation Utilities
 * 
 * Provides validation and formatting functions for user inputs and data display.
 * Includes address validation, number formatting, and error display.
 * 
 * @module cli/utils/validators
 */

/**
 * Validates Ethereum address format
 * 
 * Checks if the provided string matches the Ethereum address format:
 * 0x followed by exactly 40 hexadecimal characters.
 * 
 * @param {string | null} address - Address string to validate
 * @returns {boolean} True if valid Ethereum address format
 */
export function verifyAddress(address: string | null): boolean {
  if (!address) return false;
  return /^0x[a-fA-F0-9]{40}$/.test(address);
}

/**
 * Formats large numbers for Solidity file generation
 * 
 * Converts numbers to string representation without scientific notation
 * or grouping separators, suitable for Solidity source code.
 * 
 * @param {number | null} num - Number to format
 * @returns {string} Formatted number string
 */
export function formatNumber(num: number | null): string {
  if (num === null) return "0";
  if (num > 1e15) {
    return num.toLocaleString("fullwide", { useGrouping: false });
  }
  return num.toString();
}

/**
 * Displays formatted error message and aborts operation
 * 
 * Shows error in red with optional additional context information.
 * Used for displaying user-friendly error messages during CLI operations.
 * 
 * @param {string} message - Main error message
 * @param {string} [extraMessage] - Additional context or troubleshooting information
 */
export function showError(message: string, extraMessage: string = "") {
  const colors = {
    red: "\x1b[31m",
    reset: "\x1b[0m",
  };
  console.error(
    `${colors.red}🯀  Error: ${message}${colors.reset}\n${extraMessage}\n${colors.red}Deployment aborted.${colors.reset}`
  );
}
