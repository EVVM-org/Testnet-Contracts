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
    // Prompt for password
    const passwordResponse = await prompts({
      type: 'password',
      name: 'password',
      message: `Enter password for wallet "${walletName}":`,
    });

    if (!passwordResponse.password) {
      throw new Error('Password is required');
    }

    // Use cast wallet private-key with password via stdin
    const { stdout } = await execa('cast', [
      'wallet',
      'private-key',
      walletName,
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

    // Find Evvm contract deployment
    const evvmDeployment = artifact.transactions.find(
      (tx) => tx.contractName === 'Evvm'
    );

    if (!evvmDeployment || !evvmDeployment.contractAddress) {
      console.log(chalk.yellow('\n⚠ Evvm contract address not found in deployment artifacts'));
      return null;
    }

    return {
      evvmAddress: evvmDeployment.contractAddress,
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

    // Simulate transaction first
    console.log(chalk.gray('   Simulating transaction...'));
    const { request } = await publicClient.simulateContract({
      address: REGISTRY_ADDRESS,
      abi: REGISTRY_ABI,
      functionName: 'registerEvvm',
      args: [BigInt(chainId), evvmAddress],
      account
    });

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

    // Decode logs to get evvmID (it's the return value)
    // The registerEvvm function returns the evvmID
    // We need to read it from the transaction logs or call the contract again
    // For now, we'll parse it from logs or estimate based on publicCounter

    console.log(chalk.green('   ✓ Registration transaction confirmed!'));

    // Get the evvmID from transaction logs
    // The return value is emitted in logs, but for simplicity we can also
    // assume it's the last assigned ID. A better approach is to parse logs.

    // For now, let's use a simple approach: read the receipt logs
    // Registry typically emits the ID or we can derive it

    // We'll need to add a getter or parse events. For MVP, let's ask user to provide it
    // Or we can make another call to get the assigned ID

    console.log(chalk.yellow('   Please check the transaction on Etherscan to get your EVVM ID'));
    console.log(chalk.blue(`   https://sepolia.etherscan.io/tx/${hash}`));

    return null; // We'll improve this to actually extract the ID

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

// Deploy contracts
const deployContracts = async (
  network: string,
  wallet: string,
  customRpc?: string
): Promise<void> => {
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
    } else {
      console.log(chalk.blue(`\n🚀 Starting deployment on ${network}...`));

      await execa(
        'make',
        ['deployTestnet', `NETWORK=${network}`, `WALLET=${wallet}`],
        { stdio: 'inherit' }
      );
    }
  } catch (error) {
    console.log(chalk.red('\n✖ Deployment failed'));
    process.exit(1);
  }
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

    // Auto-registration flow (only for supported networks)
    if (networkResponse.network !== 'custom') {
      console.log(chalk.cyan('\n═══════════════════════════════════════════════════════════'));
      console.log(chalk.cyan('                    REGISTRY EVVM REGISTRATION'));
      console.log(chalk.cyan('═══════════════════════════════════════════════════════════\n'));

      // Parse deployment artifacts
      const deployment = parseDeploymentArtifacts(networkResponse.network);

      if (deployment) {
        console.log(chalk.green('✓ Deployment artifacts found'));
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
      } else {
        console.log(chalk.yellow('⚠ Could not parse deployment artifacts'));
        console.log(chalk.gray('   Automatic registration skipped'));
      }

      console.log(chalk.cyan('\n═══════════════════════════════════════════════════════════\n'));
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
