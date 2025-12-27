/**
 * Validation Utilities
 * 
 * Provides validation and formatting functions for user inputs and data display.
 * Includes address validation, number formatting, and error display.
 * 
 * @module cli/utils/validators
 */


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


