/**
 * Constants Module
 * 
 * Central repository for CLI-wide constants including color codes,
 * contract addresses, and RPC endpoints.
 * 
 * @module cli/constants
 */

/**
 * ANSI color codes for terminal output formatting
 * 
 * Provides consistent color styling throughout the CLI interface.
 * All colors are defined using ANSI escape codes for terminal compatibility.
 */
export const colors = {
  reset: "\x1b[0m",
  bright: "\x1b[1m",
  green: "\x1b[32m",
  blue: "\x1b[34m",
  yellow: "\x1b[33m",
  red: "\x1b[31m",
  darkGray: "\x1b[90m",
  evvmGreen: "\x1b[38;2;1;240;148m",
  orange: "\x1b[38;2;255;165;0m",
} as const;

/**
 * EVVM Registry contract address on Ethereum Sepolia
 * 
 * This contract manages EVVM instance registrations and chain ID validations.
 */
export const RegisteryEvvmAddress = "0x389dC8fb09211bbDA841D59f4a51160dA2377832" as const;

/**
 * Public RPC endpoint for Ethereum Sepolia testnet
 * 
 * Used for registry contract interactions when custom RPC is not specified.
 */
export const EthSepoliaPublicRpc = "https://gateway.tenderly.co/public/sepolia" as const;