#!/usr/bin/env node

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { join } from 'path';
import prompts from 'prompts';
import chalk from 'chalk';
import { config } from 'dotenv';
import { execa } from 'execa';

// Load environment variables
config();

// EVVM Brand Color (RGB: 1, 240, 148)
const evvmGreen = chalk.rgb(1, 240, 148);

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
  } else {
    console.log(chalk.yellow('\n📝 To deploy later, run:'));
    console.log(
      chalk.yellow(
        '  For predefined networks: make deployTestnet NETWORK=<eth|arb>'
      )
    );
    console.log(
      chalk.yellow(
        '  For custom RPC: forge script script/DeployTestnet.s.sol:DeployTestnet --rpc-url <YOUR_RPC_URL> --account defaultKey --broadcast --verify --etherscan-api-key $ETHERSCAN_API -vvvvvv'
      )
    );
  }

  console.log(chalk.green('\n✅ Configuration completed!'));
};

// Run main function
main().catch((error) => {
  console.error(chalk.red('Error:'), error);
  process.exit(1);
});
