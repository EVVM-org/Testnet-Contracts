/**
 * Type Definitions Module
 * 
 * Contains all TypeScript type definitions and interfaces used throughout the CLI.
 * These types ensure type safety for configuration, user inputs, and contract data.
 * 
 * @module cli/types
 */

/**
 * User confirmation responses for various CLI prompts
 * 
 * Tracks user decisions during the deployment and registration workflow.
 */
export type ConfirmAnswer = {
  configureAdvancedMetadata: string;
  confirmInputs: string;
  deploy: string;
  register: string;
  useCustomEthRpc: string;
};

/**
 * Required addresses for EVVM deployment
 * 
 * Contains all admin addresses needed to initialize the EVVM ecosystem.
 */
export type InputAddresses = {
  /** Administrator address with full system privileges */
  admin: `0x${string}` | null;
  /** Golden Fisher address for privileged staking operations */
  goldenFisher: `0x${string}` | null;
  /** Activator address for estimator epoch management */
  activator: `0x${string}` | null;
};

/**
 * Deployed contract information
 * 
 * Represents a contract that was successfully deployed during the deployment process.
 */
export interface CreatedContract {
  /** Name of the deployed contract */
  contractName: string;
  /** On-chain address of the deployed contract */
  contractAddress: `0x${string}`;
}

/**
 * EVVM metadata configuration
 * 
 * Defines the economic parameters and token information for an EVVM instance.
 */
export type EvvmMetadata = {
  /** Name of the EVVM instance */
  EvvmName: string | null;
  /** Unique identifier assigned by registry (0 during deployment) */
  EvvmID: number | null;
  /** Display name for the principal token */
  principalTokenName: string | null;
  /** Ticker symbol for the principal token */
  principalTokenSymbol: string | null;
  /** Contract address of the principal token */
  principalTokenAddress: `0x${string}` | null;
  /** Total token supply for the principal token */
  totalSupply: number | null;
  /** Token threshold for era transitions and reward halving */
  eraTokens: number | null;
  /** Base reward amount per transaction for stakers */
  reward: number | null;
};