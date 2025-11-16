#!/usr/bin/env node

import { readFileSync, writeFileSync, mkdirSync, existsSync, readdirSync } from 'fs';
import { join } from 'path';
import prompts from 'prompts';
import chalk from 'chalk';
import { config } from 'dotenv';
import { execa } from 'execa';
import {
  createPublicClient,
  createWalletClient,
  http,
  type Address,
  type Hash,
  type PublicClient,
  type WalletClient,
  parseAbi
} from 'viem';
import { sepolia as sepoliaChain, arbitrumSepolia } from 'viem/chains';
import { mnemonicToAccount, privateKeyToAccount } from 'viem/accounts';

// Load environment variables
config();

// EVVM Brand Color (RGB: 1, 240, 148)
const evvmGreen = chalk.rgb(1, 240, 148);

// Constants
const REGISTRY_ADDRESS = '0x389dC8fb09211bbDA841D59f4a51160dA2377832' as Address;
const REGISTRY_CHAIN_ID = 11155111; // Ethereum Sepolia

const CHAIN_IDS: Record<string, number> = {
  'eth': 11155111,  // Ethereum Sepolia
  'arb': 421614     // Arbitrum Sepolia
};

const CHAIN_CONFIGS: Record<string, any> = {
  'eth': sepoliaChain,
  'arb': arbitrumSepolia
};

// RPC Fallback endpoints for Ethereum Sepolia
const ETH_SEPOLIA_RPC_FALLBACKS = [
  'https://0xrpc.io/sep',                              // 0xRPC (currently in .env)
  'https://ethereum-sepolia.rpc.subquery.network/public', // SubQuery (fastest: 0.165s)
  'https://ethereum-sepolia.gateway.tatum.io',         // Tatum
  'https://sepolia.drpc.org',                          // dRPC
  'https://gateway.tenderly.co/public/sepolia',        // Tenderly
];

// RPC Fallback endpoints for Arbitrum Sepolia
const ARB_SEPOLIA_RPC_FALLBACKS = [
  'https://sepolia-rollup.arbitrum.io/rpc',           // Official Arbitrum (most reliable)
  'https://arbitrum-sepolia.gateway.tenderly.co',     // Tenderly (fastest)
  'https://endpoints.omniatech.io/v1/arbitrum/sepolia/public', // Omnia
  'https://arbitrum-sepolia.drpc.org',                // dRPC
  'https://arbitrum-sepolia-rpc.publicnode.com',      // PublicNode
];

// Contract ABIs
const REGISTRY_ABI = parseAbi([
  'function registerEvvm(uint256 chainId, address evvmAddress) external returns (uint256)'
]);

const EVVM_ABI = parseAbi([
  'function setEvvmID(uint256 evvmID) external'
]);

// Types for deployment artifacts
interface DeploymentTransaction {
  contractName?: string;
  contractAddress?: Address;
  transaction?: {
    to?: Address;
  };
}

interface DeploymentArtifact {
  transactions: DeploymentTransaction[];
  chain: number;
}

interface ParsedDeployment {
  evvmAddress: Address;
  stakingAddress: Address;
  estimatorAddress: Address;
  nameServiceAddress: Address;
  treasuryAddress: Address;
  p2pSwapAddress: Address;
  chainId: number;
  timestamp: number;
}

// Check if a command exists
const commandExists = async (command: string): Promise<boolean> => {
  try {
    await execa('which', [command]);
    return true;
  } catch {
    return false;
  }
};

// Check prerequisites
const checkPrerequisites = async (): Promise<void> => {
  console.log(chalk.blue('\n🔍 Checking prerequisites...'));

  const checks = [
    { name: 'Foundry (forge)', command: 'forge', required: true },
    { name: 'Git', command: 'git', required: true },
    { name: 'Node.js', command: 'node', required: true },
  ];

  let allPassed = true;

  for (const check of checks) {
    const exists = await commandExists(check.command);
    if (exists) {
      console.log(chalk.green(`  ✓ ${check.name}`));
    } else {
      console.log(chalk.red(`  ✖ ${check.name} not found`));
      if (check.required) {
        allPassed = false;
      }
    }
  }

  if (!allPassed) {
    console.log(chalk.red('\n✖ Missing required dependencies.'));
    console.log(chalk.yellow('\nPlease install:'));
    console.log(chalk.yellow('  - Foundry: https://getfoundry.sh/'));
    console.log(chalk.yellow('  - Git: https://git-scm.com/'));
    console.log(chalk.yellow('  - Node.js: https://nodejs.org/'));
    process.exit(1);
  }

  console.log(chalk.green('✓ All prerequisites met!\n'));
};

// Check if git submodules are initialized
const checkSubmodules = async (): Promise<boolean> => {
  const libPath = join(process.cwd(), 'lib');

  if (!existsSync(libPath)) {
    return false;
  }

  // Check if critical submodule directories are populated
  const criticalSubmodules = ['solady', 'openzeppelin-contracts', 'forge-std'];

  for (const submodule of criticalSubmodules) {
    const submodulePath = join(libPath, submodule);
    if (!existsSync(submodulePath)) {
      return false;
    }

    // Check if directory is not empty
    const files = readdirSync(submodulePath);
    if (files.length <= 1) { // Only .git or empty
      return false;
    }
  }

  return true;
};

// Initialize git submodules
const initializeSubmodules = async (): Promise<void> => {
  console.log(chalk.blue('\n📦 Initializing dependencies (git submodules)...'));
  console.log(chalk.gray('   This may take a few minutes on first run.\n'));

  try {
    await execa('git', ['submodule', 'update', '--init', '--recursive'], {
      stdio: 'inherit',
    });
    console.log(chalk.green('\n✓ Dependencies initialized successfully!\n'));
  } catch (error) {
    console.log(chalk.red('\n✖ Failed to initialize dependencies'));
    console.log(chalk.yellow('Please run manually: git submodule update --init --recursive'));
    process.exit(1);
  }
};

// Get private key from Foundry keystore
const getPrivateKeyFromWallet = async (walletName: string): Promise<`0x${string}`> => {
  try {
    // Get home directory
    const homeDir = process.env.HOME || process.env.USERPROFILE;
    if (!homeDir) {
      throw new Error('Could not determine home directory');
    }

    // Construct keystore path
    const keystorePath = join(homeDir, '.foundry', 'keystores', walletName);

    // Check if keystore exists
    if (!existsSync(keystorePath)) {
      throw new Error(`Keystore not found at: ${keystorePath}`);
    }

    // Prompt for password
    const passwordResponse = await prompts({
      type: 'password',
      name: 'password',
      message: `Enter password for wallet "${walletName}":`,
    });

    if (!passwordResponse.password) {
      throw new Error('Password is required');
    }

    // Use cast wallet private-key with keystore path and password
    const { stdout } = await execa('cast', [
      'wallet',
      'private-key',
      '--keystore',
      keystorePath,
      '--password',
      passwordResponse.password
    ]);

    return stdout.trim() as `0x${string}`;
  } catch (error: any) {
    throw new Error(`Failed to retrieve private key from wallet: ${walletName}. ${error.message || error}`);
  }
};

// Parse Foundry deployment artifacts
const parseDeploymentArtifacts = (network: string): ParsedDeployment | null => {
  try {
    const broadcastPath = join(process.cwd(), 'broadcast', 'DeployTestnet.s.sol');
    const chainId = CHAIN_IDS[network];

    if (!chainId) {
      console.log(chalk.red(`Unknown network: ${network}`));
      return null;
    }

    const runLatestPath = join(broadcastPath, `${chainId}`, 'run-latest.json');

    if (!existsSync(runLatestPath)) {
      console.log(chalk.yellow(`\n⚠ Deployment artifacts not found at: ${runLatestPath}`));
      return null;
    }

    const artifactData = readFileSync(runLatestPath, 'utf-8');
    const artifact: DeploymentArtifact = JSON.parse(artifactData);

    // Find all contract deployments
    const evvmDeployment = artifact.transactions.find(
      (tx) => tx.contractName === 'Evvm'
    );
    const stakingDeployment = artifact.transactions.find(
      (tx) => tx.contractName === 'Staking'
    );
    const estimatorDeployment = artifact.transactions.find(
      (tx) => tx.contractName === 'Estimator'
    );
    const nameServiceDeployment = artifact.transactions.find(
      (tx) => tx.contractName === 'NameService'
    );
    const treasuryDeployment = artifact.transactions.find(
      (tx) => tx.contractName === 'Treasury'
    );
    const p2pSwapDeployment = artifact.transactions.find(
      (tx) => tx.contractName === 'P2PSwap'
    );

    // Verify all contracts were deployed
    if (!evvmDeployment?.contractAddress ||
        !stakingDeployment?.contractAddress ||
        !estimatorDeployment?.contractAddress ||
        !nameServiceDeployment?.contractAddress ||
        !treasuryDeployment?.contractAddress ||
        !p2pSwapDeployment?.contractAddress) {
      console.log(chalk.yellow('\n⚠ Some contract addresses not found in deployment artifacts'));
      return null;
    }

    return {
      evvmAddress: evvmDeployment.contractAddress,
      stakingAddress: stakingDeployment.contractAddress,
      estimatorAddress: estimatorDeployment.contractAddress,
      nameServiceAddress: nameServiceDeployment.contractAddress,
      treasuryAddress: treasuryDeployment.contractAddress,
      p2pSwapAddress: p2pSwapDeployment.contractAddress,
      chainId,
      timestamp: Date.now()
    };
  } catch (error) {
    console.log(chalk.red(`\n✖ Error parsing deployment artifacts: ${error}`));
    return null;
  }
};

// Register with Registry EVVM on Ethereum Sepolia
const registerWithRegistry = async (
  chainId: number,
  evvmAddress: Address,
  walletName: string
): Promise<bigint | null> => {
  try {
    console.log(chalk.blue('\n📝 Registering with Registry EVVM on Ethereum Sepolia...'));
    console.log(chalk.gray(`   Chain ID: ${chainId}`));
    console.log(chalk.gray(`   EVVM Address: ${evvmAddress}`));

    // Get private key from wallet
    const privateKey = await getPrivateKeyFromWallet(walletName);
    const account = privateKeyToAccount(privateKey);

    // Get RPC URL for Ethereum Sepolia
    const ethSepoliaRpc = process.env.RPC_URL_ETH_SEPOLIA;
    if (!ethSepoliaRpc) {
      throw new Error('RPC_URL_ETH_SEPOLIA not found in .env file');
    }

    // Create clients
    const publicClient = createPublicClient({
      chain: sepoliaChain,
      transport: http(ethSepoliaRpc)
    });

    const walletClient = createWalletClient({
      account,
      chain: sepoliaChain,
      transport: http(ethSepoliaRpc)
    });

    // Simulate transaction first to get the return value
    console.log(chalk.gray('   Simulating transaction...'));
    const { request, result } = await publicClient.simulateContract({
      address: REGISTRY_ADDRESS,
      abi: REGISTRY_ABI,
      functionName: 'registerEvvm',
      args: [BigInt(chainId), evvmAddress],
      account
    });

    // The result contains the evvmID that will be returned
    const evvmId = result as bigint;
    console.log(chalk.gray(`   Predicted EVVM ID: ${evvmId}`));

    // Execute transaction
    console.log(chalk.gray('   Sending transaction...'));
    const hash = await walletClient.writeContract(request);
    console.log(chalk.gray(`   Transaction hash: ${hash}`));

    // Wait for transaction receipt
    console.log(chalk.gray('   Waiting for confirmation...'));
    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    if (receipt.status !== 'success') {
      throw new Error('Transaction failed');
    }

    console.log(chalk.green('   ✓ Registration transaction confirmed!'));
    console.log(chalk.blue(`   https://sepolia.etherscan.io/tx/${hash}`));

    return evvmId;

  } catch (error: any) {
    if (error.message?.includes('AlreadyRegistered')) {
      console.log(chalk.yellow('\n⚠ This EVVM instance is already registered'));
      return null;
    } else if (error.message?.includes('ChainIdNotRegistered')) {
      console.log(chalk.red('\n✖ Chain ID not whitelisted in Registry'));
      console.log(chalk.yellow('   Contact EVVM team to whitelist this chain'));
      return null;
    }

    console.log(chalk.red(`\n✖ Registration failed: ${error.message}`));
    return null;
  }
};

// Set EVVM ID on deployed Evvm contract
const setEvvmId = async (
  evvmAddress: Address,
  evvmId: bigint,
  network: string,
  walletName: string
): Promise<boolean> => {
  try {
    console.log(chalk.blue('\n🔧 Setting EVVM ID on deployed contract...'));
    console.log(chalk.gray(`   EVVM ID: ${evvmId}`));
    console.log(chalk.gray(`   Contract: ${evvmAddress}`));

    // Get private key
    const privateKey = await getPrivateKeyFromWallet(walletName);
    const account = privateKeyToAccount(privateKey);

    // Get RPC URL for deployment chain
    const rpcUrl = network === 'eth'
      ? process.env.RPC_URL_ETH_SEPOLIA
      : process.env.RPC_URL_ARB_SEPOLIA;

    if (!rpcUrl) {
      throw new Error(`RPC URL not found for network: ${network}`);
    }

    const chain = CHAIN_CONFIGS[network];
    if (!chain) {
      throw new Error(`Chain config not found for network: ${network}`);
    }

    // Create clients
    const publicClient = createPublicClient({
      chain,
      transport: http(rpcUrl)
    });

    const walletClient = createWalletClient({
      account,
      chain,
      transport: http(rpcUrl)
    });

    // Simulate transaction
    console.log(chalk.gray('   Simulating transaction...'));
    const { request } = await publicClient.simulateContract({
      address: evvmAddress,
      abi: EVVM_ABI,
      functionName: 'setEvvmID',
      args: [evvmId],
      account
    });

    // Execute transaction
    console.log(chalk.gray('   Sending transaction...'));
    const hash = await walletClient.writeContract(request);
    console.log(chalk.gray(`   Transaction hash: ${hash}`));

    // Wait for confirmation
    console.log(chalk.gray('   Waiting for confirmation...'));
    const receipt = await publicClient.waitForTransactionReceipt({ hash });

    if (receipt.status !== 'success') {
      throw new Error('Transaction failed');
    }

    console.log(chalk.green('   ✓ EVVM ID set successfully!'));
    return true;

  } catch (error: any) {
    console.log(chalk.red(`\n✖ Failed to set EVVM ID: ${error.message}`));
    return false;
  }
};

// Banner
const banner = `
${evvmGreen('░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░  ')}
${evvmGreen('░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ')}
${evvmGreen('░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ')}
${evvmGreen('░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ')}
${evvmGreen('░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ')}
${evvmGreen('░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ')}
${evvmGreen('░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ')}
`;

// Types
interface AddressConfig {
  admin: string;
  goldenFisher: string;
  activator: string;
}

interface BasicMetadata {
  EvvmName: string;
  principalTokenName: string;
  principalTokenSymbol: string;
}

interface AdvancedMetadata {
  totalSupply: string;
  eraTokens: string;
  reward: string;
}

interface ConfigurationData {
  addresses: AddressConfig;
  basicMetadata: BasicMetadata;
  advancedMetadata: AdvancedMetadata;
}

// Validation functions
const validateAddress = (address: string): boolean => {
  return /^0x[a-fA-F0-9]{40}$/.test(address);
};

const validateNumber = (value: string): boolean => {
  return /^[0-9]+$/.test(value);
};

// Prompt for Ethereum address with validation
const promptAddress = async (
  name: string,
  message: string
): Promise<string> => {
  const response = await prompts({
    type: 'text',
    name,
    message,
    validate: (value) =>
      validateAddress(value)
        ? true
        : 'Invalid address. Must be a valid Ethereum address (0x + 40 hex characters)',
  });

  if (!response[name]) {
    console.log(chalk.red('\n✖ Configuration cancelled.'));
    process.exit(1);
  }

  return response[name];
};

// Prompt for number with validation
const promptNumber = async (
  name: string,
  message: string,
  initial?: string
): Promise<string> => {
  const response = await prompts({
    type: 'text',
    name,
    message,
    initial,
    validate: (value) =>
      validateNumber(value) ? true : 'Must be a valid number',
  });

  if (response[name] === undefined) {
    console.log(chalk.red('\n✖ Configuration cancelled.'));
    process.exit(1);
  }

  return response[name];
};

// Generate JSON configuration files
const generateConfigFiles = (config: ConfigurationData): void => {
  const inputDir = join(process.cwd(), 'input');

  // Create input directory if it doesn't exist
  if (!existsSync(inputDir)) {
    mkdirSync(inputDir, { recursive: true });
  }

  // Generate address.json
  const addressPath = join(inputDir, 'address.json');
  writeFileSync(
    addressPath,
    JSON.stringify(config.addresses, null, 2) + '\n',
    'utf-8'
  );

  // Generate evvmBasicMetadata.json
  const basicMetadataPath = join(inputDir, 'evvmBasicMetadata.json');
  writeFileSync(
    basicMetadataPath,
    JSON.stringify(config.basicMetadata, null, 2) + '\n',
    'utf-8'
  );

  // Generate evvmAdvancedMetadata.json
  const advancedMetadataPath = join(inputDir, 'evvmAdvancedMetadata.json');
  const advancedMetadataJson = {
    totalSupply: config.advancedMetadata.totalSupply,
    eraTokens: config.advancedMetadata.eraTokens,
    reward: config.advancedMetadata.reward,
  };
  writeFileSync(
    advancedMetadataPath,
    JSON.stringify(advancedMetadataJson, null, 2) + '\n',
    'utf-8'
  );

  console.log(chalk.green('\n✅ Configuration files generated:'));
  console.log('   - input/address.json');
  console.log('   - input/evvmBasicMetadata.json');
  console.log('   - input/evvmAdvancedMetadata.json');
};

// Get available Foundry wallets
const getAvailableWallets = async (): Promise<string[]> => {
  try {
    const { stdout } = await execa('cast', ['wallet', 'list']);
    const wallets = stdout
      .split('\n')
      .filter((line) => line.trim())
      .map((line) => line.replace(' (Local)', '').trim());
    return wallets;
  } catch (error) {
    console.log(chalk.yellow('\n⚠ Could not retrieve wallet list'));
    return [];
  }
};

// Deploy contracts with RPC fallback mechanism
const deployContracts = async (
  network: string,
  wallet: string,
  customRpc?: string
): Promise<void> => {
  // Determine fallback endpoints and retry count based on network
  const fallbackRpcs = network === 'eth' ? ETH_SEPOLIA_RPC_FALLBACKS
                     : network === 'arb' ? ARB_SEPOLIA_RPC_FALLBACKS
                     : [];
  const maxRetries = fallbackRpcs.length || 1;
  const hasFailover = fallbackRpcs.length > 0;
  let lastError: any;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      if (network === 'custom' && customRpc) {
        console.log(chalk.blue('\n🚀 Starting deployment on custom network...'));

        const etherscanApi = process.env.ETHERSCAN_API || '';

        await execa(
          'forge',
          [
            'script',
            'script/DeployTestnet.s.sol:DeployTestnet',
            '--rpc-url',
            customRpc,
            '--account',
            wallet,
            '--broadcast',
            '--verify',
            '--etherscan-api-key',
            etherscanApi,
            '-vvvvvv',
          ],
          { stdio: 'inherit' }
        );
      } else if (hasFailover && attempt > 0) {
        // Use fallback RPC for supported networks
        const fallbackRpc = fallbackRpcs[attempt];
        const networkName = network === 'eth' ? 'Ethereum Sepolia' : 'Arbitrum Sepolia';
        console.log(chalk.yellow(`\n⚠ Trying fallback RPC (${attempt}/${maxRetries - 1}) for ${networkName}:`));
        console.log(chalk.gray(`   ${fallbackRpc}`));

        const etherscanApi = process.env.ETHERSCAN_API || '';

        await execa(
          'forge',
          [
            'script',
            'script/DeployTestnet.s.sol:DeployTestnet',
            '--rpc-url',
            fallbackRpc,
            '--account',
            wallet,
            '--broadcast',
            '--verify',
            '--etherscan-api-key',
            etherscanApi,
            '-vvvvvv',
          ],
          { stdio: 'inherit' }
        );
      } else {
        // Use makefile for first attempt
        if (attempt === 0 && hasFailover) {
          const networkName = network === 'eth' ? 'Ethereum Sepolia' : 'Arbitrum Sepolia';
          console.log(chalk.blue(`\n🚀 Starting deployment on ${networkName}...`));
          console.log(chalk.gray(`   Using primary RPC from .env file`));
        } else {
          console.log(chalk.blue(`\n🚀 Starting deployment on ${network}...`));
        }

        await execa(
          'make',
          ['deployTestnet', `NETWORK=${network}`, `WALLET=${wallet}`],
          { stdio: 'inherit' }
        );
      }

      // If we reach here, deployment succeeded
      return;

    } catch (error) {
      lastError = error;

      // If we have more fallbacks available, continue to next attempt
      if (hasFailover && attempt < maxRetries - 1) {
        console.log(chalk.yellow(`\n⚠ Deployment attempt ${attempt + 1} failed, trying next RPC endpoint...`));
        continue;
      }

      // No more retries available
      break;
    }
  }

  // All attempts failed
  console.log(chalk.red('\n✖ Deployment failed after trying all available RPC endpoints'));
  if (hasFailover) {
    const networkName = network === 'eth' ? 'Ethereum Sepolia' : 'Arbitrum Sepolia';
    const envVar = network === 'eth' ? 'RPC_URL_ETH_SEPOLIA' : 'RPC_URL_ARB_SEPOLIA';
    console.log(chalk.yellow('\n💡 Troubleshooting tips:'));
    console.log(chalk.gray('   1. Check your internet connection'));
    console.log(chalk.gray('   2. Verify your wallet has sufficient ETH for gas fees'));
    console.log(chalk.gray('   3. Try again later - RPC endpoints may be temporarily unavailable'));
    console.log(chalk.gray(`   4. Update ${envVar} in .env with a custom endpoint`));
    console.log(chalk.gray(`   5. Visit https://chainlist.org/ for more ${networkName} RPC endpoints`));
  }
  process.exit(1);
};

// Main function
const main = async (): Promise<void> => {
  console.log(banner);

  // Check prerequisites
  await checkPrerequisites();

  // Check and initialize submodules if needed
  const submodulesInitialized = await checkSubmodules();
  if (!submodulesInitialized) {
    console.log(chalk.yellow('⚠ Dependencies not initialized. Initializing now...'));
    await initializeSubmodules();
  } else {
    console.log(chalk.green('✓ Dependencies already initialized\n'));
  }

  console.log(chalk.yellow('Configuring deployment variables...\n'));

  // Parse command line arguments
  const shouldDeployImmediately = process.argv.includes('--deploy');

  // Administrator Configuration
  console.log(chalk.green('=== Administrator Configuration ==='));

  const admin = await promptAddress('admin', 'Admin address (0x...):');
  const goldenFisher = await promptAddress(
    'goldenFisher',
    'Golden Fisher address (0x...):'
  );
  const activator = await promptAddress(
    'activator',
    'Activator address (0x...):'
  );

  // EVVM Metadata Configuration
  console.log(chalk.green('\n=== EVVM Metadata Configuration ==='));

  const basicMetadataResponse = await prompts([
    {
      type: 'text',
      name: 'EvvmName',
      message: `EVVM Name ${chalk.gray('[EVVM]')}:`,
      initial: 'EVVM',
    },
    {
      type: 'text',
      name: 'principalTokenName',
      message: `Principal Token Name ${chalk.gray('[Mate token]')}:`,
      initial: 'Mate token',
    },
    {
      type: 'text',
      name: 'principalTokenSymbol',
      message: `Principal Token Symbol ${chalk.gray('[MATE]')}:`,
      initial: 'MATE',
    },
  ]);

  if (
    !basicMetadataResponse.EvvmName ||
    !basicMetadataResponse.principalTokenName ||
    !basicMetadataResponse.principalTokenSymbol
  ) {
    console.log(chalk.red('\n✖ Configuration cancelled.'));
    process.exit(1);
  }

  // Advanced Configuration
  console.log(chalk.blue('\n=== Advanced Configuration (Optional) ==='));

  const configAdvancedResponse = await prompts({
    type: 'confirm',
    name: 'configAdvanced',
    message: 'Do you want to configure advanced metadata?',
    initial: false,
  });

  let advancedMetadata: AdvancedMetadata;

  if (configAdvancedResponse.configAdvanced) {
    const totalSupply = await promptNumber(
      'totalSupply',
      `Total Supply ${chalk.gray('[2033333333000000000000000000]')}:`,
      '2033333333000000000000000000'
    );

    const eraTokens = await promptNumber(
      'eraTokens',
      `Era Tokens ${chalk.gray('[1016666666500000000000000000]')}:`,
      '1016666666500000000000000000'
    );

    const reward = await promptNumber(
      'reward',
      `Reward per operation ${chalk.gray('[5000000000000000000]')}:`,
      '5000000000000000000'
    );

    advancedMetadata = { totalSupply, eraTokens, reward };
  } else {
    console.log(chalk.yellow('Using default advanced values'));
    advancedMetadata = {
      totalSupply: '2033333333000000000000000000',
      eraTokens: '1016666666500000000000000000',
      reward: '5000000000000000000',
    };
  }

  // Configuration Summary
  const config: ConfigurationData = {
    addresses: { admin, goldenFisher, activator },
    basicMetadata: basicMetadataResponse,
    advancedMetadata,
  };

  console.log(chalk.yellow('\n=== Configuration Summary ==='));
  console.log(`Admin: ${chalk.green(config.addresses.admin)}`);
  console.log(`Golden Fisher: ${chalk.green(config.addresses.goldenFisher)}`);
  console.log(`Activator: ${chalk.green(config.addresses.activator)}`);
  console.log(`EVVM Name: ${chalk.green(config.basicMetadata.EvvmName)}`);
  console.log(
    `Principal Token Name: ${chalk.green(config.basicMetadata.principalTokenName)}`
  );
  console.log(
    `Principal Token Symbol: ${chalk.green(config.basicMetadata.principalTokenSymbol)}`
  );
  console.log(`Total Supply: ${chalk.green(config.advancedMetadata.totalSupply)}`);
  console.log(`Era Tokens: ${chalk.green(config.advancedMetadata.eraTokens)}`);
  console.log(`Reward: ${chalk.green(config.advancedMetadata.reward)}`);

  const confirmResponse = await prompts({
    type: 'confirm',
    name: 'confirm',
    message: 'Is the data correct?',
    initial: true,
  });

  if (!confirmResponse.confirm) {
    console.log(chalk.red('\n✖ Configuration cancelled.'));
    process.exit(1);
  }

  // Generate configuration files
  generateConfigFiles(config);

  // Deployment
  let shouldDeploy = shouldDeployImmediately;

  if (!shouldDeployImmediately) {
    const deployNowResponse = await prompts({
      type: 'confirm',
      name: 'deployNow',
      message: 'Do you want to deploy the contracts now?',
      initial: false,
    });

    shouldDeploy = deployNowResponse.deployNow;
  }

  if (shouldDeploy) {
    console.log(chalk.green('\n=== Network Selection ==='));
    console.log('Available networks:');
    console.log('  eth    - Ethereum Sepolia');
    console.log('  arb    - Arbitrum Sepolia');
    console.log('  custom - Custom RPC URL\n');

    const networkResponse = await prompts({
      type: 'select',
      name: 'network',
      message: 'Select network:',
      choices: [
        { title: 'Ethereum Sepolia', value: 'eth' },
        { title: 'Arbitrum Sepolia', value: 'arb' },
        { title: 'Custom RPC URL', value: 'custom' },
      ],
      initial: 0,
    });

    if (!networkResponse.network) {
      console.log(chalk.red('\n✖ Deployment cancelled.'));
      process.exit(1);
    }

    let customRpc: string | undefined;

    if (networkResponse.network === 'custom') {
      console.log(chalk.blue('\n=== Custom Network Configuration ==='));
      const rpcResponse = await prompts({
        type: 'text',
        name: 'rpcUrl',
        message: 'Enter RPC URL:',
        validate: (value) => (value ? true : 'RPC URL is required'),
      });

      if (!rpcResponse.rpcUrl) {
        console.log(chalk.red('\n✖ Deployment cancelled.'));
        process.exit(1);
      }

      customRpc = rpcResponse.rpcUrl;
    }

    // Wallet Selection
    console.log(chalk.green('\n=== Wallet Selection ==='));
    const availableWallets = await getAvailableWallets();

    if (availableWallets.length === 0) {
      console.log(chalk.red('✖ No wallets found. Please import a wallet using:'));
      console.log(chalk.yellow('  cast wallet import <WALLET_NAME> --interactive'));
      process.exit(1);
    }

    const walletResponse = await prompts({
      type: 'select',
      name: 'wallet',
      message: 'Select wallet for deployment:',
      choices: availableWallets.map((wallet) => ({
        title: wallet,
        value: wallet,
      })),
      initial: 0,
    });

    if (!walletResponse.wallet) {
      console.log(chalk.red('\n✖ Deployment cancelled.'));
      process.exit(1);
    }

    await deployContracts(networkResponse.network, walletResponse.wallet, customRpc);

    console.log(chalk.green('\n🎉 Deployment completed!'));

    // Parse deployment artifacts and display summary
    const deployment = networkResponse.network !== 'custom'
      ? parseDeploymentArtifacts(networkResponse.network)
      : null;

    if (deployment) {
      // Display deployment summary
      console.log(chalk.cyan('\n═══════════════════════════════════════════════════════════'));
      console.log(chalk.cyan('                 DEPLOYED CONTRACTS SUMMARY'));
      console.log(chalk.cyan('═══════════════════════════════════════════════════════════\n'));

      const networkName = networkResponse.network === 'eth' ? 'Ethereum Sepolia' : 'Arbitrum Sepolia';
      const explorerBase = networkResponse.network === 'eth'
        ? 'https://sepolia.etherscan.io/address/'
        : 'https://sepolia.arbiscan.io/address/';

      console.log(chalk.white(`Network: ${chalk.green(networkName)} (Chain ID: ${deployment.chainId})\n`));

      console.log(chalk.yellow('Core Contracts:'));
      console.log(chalk.white(`  EVVM:        ${chalk.green(deployment.evvmAddress)}`));
      console.log(chalk.gray(`               ${explorerBase}${deployment.evvmAddress}`));
      console.log(chalk.white(`  Treasury:    ${chalk.green(deployment.treasuryAddress)}`));
      console.log(chalk.gray(`               ${explorerBase}${deployment.treasuryAddress}\n`));

      console.log(chalk.yellow('Supporting Contracts:'));
      console.log(chalk.white(`  Staking:     ${chalk.green(deployment.stakingAddress)}`));
      console.log(chalk.gray(`               ${explorerBase}${deployment.stakingAddress}`));
      console.log(chalk.white(`  Estimator:   ${chalk.green(deployment.estimatorAddress)}`));
      console.log(chalk.gray(`               ${explorerBase}${deployment.estimatorAddress}`));
      console.log(chalk.white(`  NameService: ${chalk.green(deployment.nameServiceAddress)}`));
      console.log(chalk.gray(`               ${explorerBase}${deployment.nameServiceAddress}`));
      console.log(chalk.white(`  P2PSwap:     ${chalk.green(deployment.p2pSwapAddress)}`));
      console.log(chalk.gray(`               ${explorerBase}${deployment.p2pSwapAddress}`));

      console.log(chalk.cyan('\n═══════════════════════════════════════════════════════════\n'));
    }

    // Auto-registration flow (only for supported networks)
    if (networkResponse.network !== 'custom' && deployment) {
      console.log(chalk.cyan('═══════════════════════════════════════════════════════════'));
      console.log(chalk.cyan('                    REGISTRY EVVM REGISTRATION'));
      console.log(chalk.cyan('═══════════════════════════════════════════════════════════\n'));

      console.log(chalk.gray(`  EVVM Address: ${deployment.evvmAddress}`));
      console.log(chalk.gray(`  Chain ID: ${deployment.chainId}\n`));

        const registerPrompt = await prompts({
          type: 'confirm',
          name: 'register',
          message: 'Register with Registry EVVM automatically?',
          initial: true
        });

        if (registerPrompt.register) {
          const evvmId = await registerWithRegistry(
            deployment.chainId,
            deployment.evvmAddress,
            walletResponse.wallet
          );

          if (evvmId !== null) {
            // Successfully registered, now set the EVVM ID
            console.log(chalk.green(`\n✓ EVVM registered! ID: ${evvmId}`));

            const setIdPrompt = await prompts({
              type: 'confirm',
              name: 'setId',
              message: 'Set EVVM ID on deployed contract now?',
              initial: true
            });

            if (setIdPrompt.setId) {
              await setEvvmId(
                deployment.evvmAddress,
                evvmId,
                networkResponse.network,
                walletResponse.wallet
              );
            } else {
              console.log(chalk.yellow('\n⚠ Remember to set EVVM ID within 1 hour!'));
              console.log(chalk.gray(`  EVVM ID: ${evvmId}`));
              console.log(chalk.gray(`  Contract: ${deployment.evvmAddress}`));
            }
          } else {
            // Registration returned null - check Etherscan or already registered
            console.log(chalk.yellow('\n⚠ Please verify registration status manually'));
          }
      } else {
        console.log(chalk.yellow('\n⚠ Skipping automatic registration'));
        console.log(chalk.gray('   You will need to register manually later'));
      }

      console.log(chalk.cyan('\n═══════════════════════════════════════════════════════════\n'));
    } else if (networkResponse.network === 'custom') {
      console.log(chalk.yellow('\n⚠ Deployment artifacts not available for custom networks'));
      console.log(chalk.gray('   Manual registration required\n'));
    }

    // Post-deployment instructions
    console.log(chalk.cyan('═══════════════════════════════════════════════════════════'));
    console.log(chalk.cyan('                    IMPORTANT NEXT STEPS'));
    console.log(chalk.cyan('═══════════════════════════════════════════════════════════\n'));

    if (networkResponse.network === 'custom') {
      console.log(chalk.yellow('📋 1. Register with Registry EVVM (REQUIRED)'));
      console.log(chalk.gray('   All EVVM deployments must register on Ethereum Sepolia'));
      console.log(chalk.gray('   to obtain an official EVVM ID.\n'));
      console.log(chalk.blue('   Registration contract: Ethereum Sepolia'));
      console.log(chalk.blue('   Address: 0x389dC8fb09211bbDA841D59f4a51160dA2377832'));
      console.log(chalk.gray('   You will need ETH Sepolia tokens for gas fees.\n'));

      console.log(chalk.yellow('📋 2. Configure EVVM ID (within 1 hour)'));
      console.log(chalk.gray('   After registration, update your deployed contracts with'));
      console.log(chalk.gray('   the assigned EVVM ID within the one-hour window.\n'));
    }

    console.log(chalk.yellow(`📋 ${networkResponse.network === 'custom' ? '3' : '1'}. Verify Deployment`));
    console.log(chalk.gray('   Check the broadcast/ directory for deployment artifacts'));
    console.log(chalk.gray('   and transaction receipts.\n'));

    console.log(chalk.yellow(`📋 ${networkResponse.network === 'custom' ? '4' : '2'}. Explore Documentation`));
    console.log(chalk.gray('   Learn more at: https://www.evvm.info/docs\n'));

    console.log(chalk.cyan('═══════════════════════════════════════════════════════════\n'));
  } else {
    console.log(chalk.yellow('\n📝 To deploy later, run:'));
    console.log(
      chalk.yellow(
        '  For predefined networks: make deployTestnet NETWORK=<eth|arb> WALLET=<wallet-name>'
      )
    );
    console.log(
      chalk.yellow(
        '  For custom RPC: forge script script/DeployTestnet.s.sol:DeployTestnet --rpc-url <YOUR_RPC_URL> --account <WALLET_NAME> --broadcast --verify --etherscan-api-key $ETHERSCAN_API -vvvvvv'
      )
    );
  }

  console.log(chalk.green('\n✅ Configuration wizard completed!'));
};

// Run main function
main().catch((error) => {
  console.error(chalk.red('Error:'), error);
  process.exit(1);
});
