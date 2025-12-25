/**
 * Type Definitions Module
 *
 * Contains all TypeScript type definitions and interfaces used throughout the CLI.
 * These types ensure type safety for configuration, user inputs, and contract data.
 *
 * @module cli/types
 */

/**
 * Required addresses for EVVM deployment
 *
 * Contains all admin addresses needed to initialize the EVVM ecosystem.
 */
export type BaseInputAddresses = {
  /** Administrator address with full system privileges */
  admin: `0x${string}` | null;
  /** Golden Fisher address for privileged staking operations */
  goldenFisher: `0x${string}` | null;
  /** Activator address for estimator epoch management */
  activator: `0x${string}` | null;
};

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

export type CrossChainInputs = {
  adminExternal: `0x${string}`;
  crosschainConfigHost: {
    hyperlane: {
      externalChainStationDomainId: number;
      mailboxAddress: `0x${string}`;
    };
    layerZero: {
      externalChainStationEid: number;
      endpointAddress: `0x${string}`;
    };
    axelar: {
      externalChainStationChainName: string;
      gasServiceAddress: `0x${string}`;
      gatewayAddress: `0x${string}`;
    };
  };
  crosschainConfigExternal: {
    hyperlane: {
      hostChainStationDomainId: number;
      mailboxAddress: `0x${string}`;
    };
    layerZero: {
      hostChainStationEid: number;
      endpointAddress: `0x${string}`;
    };
    axelar: {
      hostChainStationChainName: string;
      gasServiceAddress: `0x${string}`;
      gatewayAddress: `0x${string}`;
    };
  };
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

export type HyperlaneType = {
  [chainID: number]: HyperlaneMetadata;
};

export type HyperlaneMetadata = {
  hyperlaneDomainId: number | null;
  hyperlaneMailboxAddress: `0x${string}` | null;
};

export type ChainData = {
  Chain: string;
  Hyperlane: {
    DomainId: number;
    MailboxAddress: string;
  };
  LayerZero: {
    EId: number;
    EndpointAddress: string;
  };
  Axelar: {
    ChainName: string;
    Gateway: string;
    GasService: string;
  };
  ExplorerToAddress: string;
};

export type ChainDataType = {
  [chainID: number]: ChainData;
};

export type ContractFileMetadata = {
  contractName: string;
  folderName: string;
};
