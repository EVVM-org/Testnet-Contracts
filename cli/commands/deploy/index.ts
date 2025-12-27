/**
 * EVVM Deployment Command Dispatcher
 *
 * Routes deployment requests to either single-chain or cross-chain
 * deployment workflows based on the --crossChain flag.
 *
 * @module cli/commands/deploy
 */

import { deploySingle } from "./deploySingle";
import { deployCross } from "./deployCross";

/**
 * Routes deployment command to appropriate workflow
 *
 * Determines whether to execute a single-chain deployment (deploySingle)
 * or a cross-chain deployment (deployCross) based on the --crossChain flag.
 *
 * Single-chain deployment: Deploys EVVM on one blockchain
 * Cross-chain deployment: Deploys EVVM with treasury stations on two chains
 *
 * @param {string[]} args - Command-line arguments passed to deployment
 * @param {any} options - Command options including:
 *   - crossChain: Boolean flag to enable cross-chain mode
 *   - skipInputConfig: Skip interactive configuration
 *   - walletName/walletNameHost/walletNameExternal: Wallet accounts
 * @returns {Promise<void>}
 */
export async function deploy(args: string[], options: any) {
  return options.crossChain || false
    ? deployCross(args, options)
    : deploySingle(args, options);
}
