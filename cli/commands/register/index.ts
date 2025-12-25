import { registerSingle } from "./registerSingle";
import { registerCross } from "./registerCross";

/**
 * Unified register command: delegates to single or cross-chain flows.
 */

export async function register(args: string[], options: any) {
  return options.crossChain || false
    ? registerCross(args, options)
    : registerSingle(args, options);
}
