import { deploySingle } from "./deploySingle";
import { deployCross } from "./deployCross";

/**
 * Unified deploy command: delegates to single or cross-chain flows.
 */

export async function deploy(args: string[], options: any) {
  return options.crossChain || false
    ? deployCross(args, options)
    : deploySingle(args, options);
}
