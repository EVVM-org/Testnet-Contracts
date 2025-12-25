/**
 * RPC Utilities
 * 
 * Provides functions for RPC endpoint management and chain ID retrieval.
 * Handles RPC URL validation and fetching chain information from RPC endpoints.
 * 
 * @module cli/utils/rpc
 */

import { colors } from "../constants";

/**
 * Gets RPC URL from environment or prompts user, then fetches chain ID
 * 
 * If RPC URL is not provided in environment variables, prompts the user
 * to enter it. Then queries the RPC endpoint to retrieve the chain ID.
 * 
 * @param {string | undefined | null} rpcUrl - Optional RPC URL from environment
 * @returns {Promise<{rpcUrl: string, chainId: number}>} RPC URL and chain ID
 */
export async function getRPCUrlAndChainId(
  rpcUrl: string | undefined | null,
  stringPrompt = `${colors.yellow}Please enter the RPC URL for deployment:${colors.reset}`
): Promise<{
  rpcUrl: string;
  chainId: number;
}> {
  if (!rpcUrl) rpcUrl = null;

  while (!rpcUrl) {
    console.log(
      `${colors.orange}RPC URL not found in .env file.${colors.reset}`
    );
    rpcUrl = prompt(
      stringPrompt
    );
    if (!rpcUrl) {
      console.log(
        `${colors.red}RPC URL cannot be empty. Please enter a valid RPC URL.${colors.reset}`
      );
    }
  }

  const chainId = await getChainId(rpcUrl);

  return { rpcUrl, chainId };
}

/**
 * Fetches chain ID from an RPC endpoint
 * 
 * Makes an eth_chainId RPC call to retrieve the chain ID and converts
 * the hexadecimal result to a decimal number.
 * 
 * @param {string} rpcUrl - RPC endpoint URL
 * @returns {Promise<number>} Chain ID as decimal number
 * @throws {Error} If RPC request fails
 */
export async function getChainId(rpcUrl: string): Promise<number> {
  const response = await fetch(rpcUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      jsonrpc: "2.0",
      method: "eth_chainId",
      params: [],
      id: 1,
    }),
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch chain ID: ${response.statusText}`);
  }
  const data = (await response.json()) as { result: string };
  return parseInt(data.result, 16);
}