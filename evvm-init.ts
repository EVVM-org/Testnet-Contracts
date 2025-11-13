#!/usr/bin/env node

import * as fs from 'fs';
import * as path from 'path';
import * as readline from 'readline';
import { execSync } from 'child_process';
import { config } from 'dotenv';

// Load environment variables
config();

// Color definitions
const colors = {
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  gray: '\x1b[90m',
  evvmGreen: '\x1b[38;2;1;240;148m',
  reset: '\x1b[0m'
};

// Type definitions
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

interface DeploymentConfig extends AddressConfig, BasicMetadata, AdvancedMetadata {}

class EVVMInitializer {
  private rl: readline.Interface;
  private config: Partial<DeploymentConfig> = {};

  constructor() {
    this.rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    // Handle Ctrl+C and other termination signals
    this.setupSignalHandlers();
  }

  private setupSignalHandlers(): void {
    const cleanup = () => {
      console.log('\n');
      this.log('Operation cancelled by user.', 'yellow');
      this.rl.close();
      process.exit(0);
    };

    // Handle various termination signals
    process.on('SIGINT', cleanup);  // Ctrl+C
    process.on('SIGTERM', cleanup); // Termination request
    process.on('SIGQUIT', cleanup); // Quit request
    
    // Handle readline interface close
    this.rl.on('SIGINT', cleanup);
  }

  private async question(prompt: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.rl.question(prompt, resolve);
      
      // Handle case where readline is closed/interrupted
      this.rl.once('close', () => {
        reject(new Error('Input stream closed'));
      });
    });
  }

  private log(message: string, color?: keyof typeof colors): void {
    const colorCode = color ? colors[color] : '';
    console.log(`${colorCode}${message}${colors.reset}`);
  }

  private showBanner(): void {
    this.log('░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░  ', 'evvmGreen');
    this.log('░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ', 'evvmGreen');
    this.log('░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ', 'evvmGreen');
    this.log('░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ', 'evvmGreen');
    this.log('░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ', 'evvmGreen');
    this.log('░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ', 'evvmGreen');
    this.log('░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ ', 'evvmGreen');
    console.log();
  }

  private validateAddress(address: string): boolean {
    // Remove whitespace
    const cleanAddr = address.trim().replace(/\s+/g, '');
    
    // Ethereum address pattern: 0x + 40 hex characters
    const addressRegex = /^0x[a-fA-F0-9]{40}$/;
    return addressRegex.test(cleanAddr);
  }

  private validateNumber(value: string): boolean {
    const cleanValue = value.trim();
    return /^\d+$/.test(cleanValue);
  }

  private async getValidAddress(prompt: string): Promise<string> {
    while (true) {
      const input = await this.question(prompt);
      const cleanAddress = input.trim().replace(/\s+/g, '');
      
      if (this.validateAddress(cleanAddress)) {
        this.log(`✓ Valid address: ${cleanAddress}`, 'gray');
        return cleanAddress;
      } else {
        this.log('Error: Invalid address. Must be a valid Ethereum address (0x + 40 hex characters)', 'red');
        this.log('Example: 0x63c3774531EF83631111Fe2Cf01520Fb3F5A68F7', 'gray');
      }
    }
  }

  private async getValidNumber(prompt: string, defaultValue?: string): Promise<string> {
    while (true) {
      const input = await this.question(prompt);
      const value = input.trim() || defaultValue || '';
      
      if (this.validateNumber(value)) {
        return value;
      } else {
        this.log('Error: Must be a valid number', 'red');
      }
    }
  }

  private async getInput(prompt: string, defaultValue?: string): Promise<string> {
    const input = await this.question(prompt);
    return input.trim() || defaultValue || '';
  }

  private async collectAddresses(): Promise<void> {
    this.log('=== Administrator Configuration ===', 'green');
    
    this.config.admin = await this.getValidAddress('Admin address (0x...): ');
    this.config.goldenFisher = await this.getValidAddress('Golden Fisher address (0x...): ');
    this.config.activator = await this.getValidAddress('Activator address (0x...): ');
  }

  private async collectBasicMetadata(): Promise<void> {
    this.log('=== EVVM Metadata Configuration ===', 'green');
    
    this.config.EvvmName = await this.getInput(
      `EVVM Name ${colors.gray}[EVVM]${colors.reset}: `, 
      'EVVM'
    );
    
    this.config.principalTokenName = await this.getInput(
      `Principal Token Name ${colors.gray}[Mate token]${colors.reset}: `, 
      'Mate token'
    );
    
    this.config.principalTokenSymbol = await this.getInput(
      `Principal Token Symbol ${colors.gray}[MATE]${colors.reset}: `, 
      'MATE'
    );
  }

  private async collectAdvancedMetadata(): Promise<void> {
    console.log();
    this.log('=== Advanced Configuration (Optional) ===', 'blue');
    
    const configAdvanced = await this.getInput(
      `Do you want to configure advanced metadata? (y/n) ${colors.gray}[n]${colors.reset}: `, 
      'n'
    );

    if (configAdvanced.toLowerCase() === 'y') {
      this.config.totalSupply = await this.getValidNumber(
        `Total Supply ${colors.gray}[2033333333000000000000000000]${colors.reset}: `,
        '2033333333000000000000000000'
      );

      this.config.eraTokens = await this.getValidNumber(
        `Era Tokens ${colors.gray}[1016666666500000000000000000]${colors.reset}: `,
        '1016666666500000000000000000'
      );

      this.config.reward = await this.getValidNumber(
        `Reward per operation ${colors.gray}[5000000000000000000]${colors.reset}: `,
        '5000000000000000000'
      );
    } else {
      // Default values
      this.config.totalSupply = '2033333333000000000000000000';
      this.config.eraTokens = '1016666666500000000000000000';
      this.config.reward = '5000000000000000000';
      this.log('Using default advanced values', 'yellow');
    }
  }

  private showSummary(): void {
    console.log();
    this.log('=== Configuration Summary ===', 'yellow');
    this.log(`Admin: ${colors.green}${this.config.admin}${colors.reset}`);
    this.log(`Golden Fisher: ${colors.green}${this.config.goldenFisher}${colors.reset}`);
    this.log(`Activator: ${colors.green}${this.config.activator}${colors.reset}`);
    this.log(`EVVM Name: ${colors.green}${this.config.EvvmName}${colors.reset}`);
    this.log(`Principal Token Name: ${colors.green}${this.config.principalTokenName}${colors.reset}`);
    this.log(`Principal Token Symbol: ${colors.green}${this.config.principalTokenSymbol}${colors.reset}`);
    this.log(`Total Supply: ${colors.green}${this.config.totalSupply}${colors.reset}`);
    this.log(`Era Tokens: ${colors.green}${this.config.eraTokens}${colors.reset}`);
    this.log(`Reward: ${colors.green}${this.config.reward}${colors.reset}`);
  }

  private async confirmConfiguration(): Promise<boolean> {
    console.log();
    const confirm = await this.question('Is the data correct? (y/n): ');
    return confirm.toLowerCase() === 'y';
  }

  private ensureInputDirectory(): void {
    const inputDir = path.join(process.cwd(), 'input');
    if (!fs.existsSync(inputDir)) {
      fs.mkdirSync(inputDir, { recursive: true });
    }
  }

  private generateConfigFiles(): void {
    this.ensureInputDirectory();

    // Address file
    const addressConfig: AddressConfig = {
      admin: this.config.admin!,
      goldenFisher: this.config.goldenFisher!,
      activator: this.config.activator!
    };

    // Basic metadata file
    const basicMetadata: BasicMetadata = {
      EvvmName: this.config.EvvmName!,
      principalTokenName: this.config.principalTokenName!,
      principalTokenSymbol: this.config.principalTokenSymbol!
    };

    // Write files
    fs.writeFileSync(
      path.join('input', 'address.json'),
      JSON.stringify(addressConfig, null, 2)
    );

    fs.writeFileSync(
      path.join('input', 'evvmBasicMetadata.json'),
      JSON.stringify(basicMetadata, null, 2)
    );

    // Advanced metadata file - write manually to preserve large numbers
    const advancedJson = `{
  "totalSupply": ${this.config.totalSupply!},
  "eraTokens": ${this.config.eraTokens!},
  "reward": ${this.config.reward!}
}`;

    fs.writeFileSync(
      path.join('input', 'evvmAdvancedMetadata.json'),
      advancedJson
    );

    this.log('✅ Configuration files generated:', 'green');
    this.log('   - input/address.json');
    this.log('   - input/evvmBasicMetadata.json');
    this.log('   - input/evvmAdvancedMetadata.json');
  }

  private async handleDeployment(): Promise<void> {
    console.log();
    const deployNow = await this.question('Do you want to deploy the contracts now? (y/n): ');

    if (deployNow.toLowerCase() === 'y') {
      await this.selectNetworkAndDeploy();
    } else {
      this.log('To deploy later, run:', 'yellow');
      this.log('  For predefined networks: make deployTestnet NETWORK=<eth|arb>', 'yellow');
      this.log('  For custom RPC: forge script script/DeployTestnet.s.sol:DeployTestnet --rpc-url <YOUR_RPC_URL> --account defaultKey --broadcast --verify --etherscan-api-key $ETHERSCAN_API -vvvvvv', 'yellow');
    }
  }

  private async selectNetworkAndDeploy(): Promise<void> {
    this.log('=== Network Selection ===', 'green');
    this.log('Available networks:');
    this.log('  eth    - Ethereum Sepolia');
    this.log('  arb    - Arbitrum Sepolia');
    this.log('  custom - Custom RPC URL');
    console.log();

    let network: string;
    while (true) {
      network = await this.getInput(
        `Select network (eth/arb/custom) ${colors.gray}[eth]${colors.reset}: `,
        'eth'
      );

      if (['eth', 'arb', 'custom'].includes(network)) {
        break;
      } else {
        this.log("Error: Invalid network. Use 'eth', 'arb', or 'custom'", 'red');
      }
    }

    if (network === 'custom') {
      await this.deployCustomNetwork();
    } else {
      await this.deployPredefinedNetwork(network);
    }
  }

  private async deployCustomNetwork(): Promise<void> {
    this.log('=== Custom Network Configuration ===', 'blue');
    
    let rpcUrl: string;
    while (true) {
      rpcUrl = await this.question('Enter RPC URL: ');
      if (rpcUrl.trim()) {
        break;
      } else {
        this.log('Error: RPC URL is required', 'red');
      }
    }

    this.log('Starting deployment on custom network...', 'blue');
    
    try {
      const command = `forge script script/DeployTestnet.s.sol:DeployTestnet --rpc-url "${rpcUrl}" --account defaultKey --broadcast --verify --etherscan-api-key $ETHERSCAN_API -vvvvvv`;
      execSync(command, { stdio: 'inherit' });
    } catch (error) {
      this.log(`Deployment failed: ${error}`, 'red');
      process.exit(1);
    }
  }

  private async deployPredefinedNetwork(network: string): Promise<void> {
    this.log(`Starting deployment on ${network}...`, 'blue');
    
    try {
      const command = `make deployTestnet NETWORK=${network}`;
      execSync(command, { stdio: 'inherit' });
    } catch (error) {
      this.log(`Deployment failed: ${error}`, 'red');
      process.exit(1);
    }
  }

  public async run(): Promise<void> {
    try {
      this.showBanner();
      this.log('Configuring deployment variables...', 'yellow');
      console.log();

      await this.collectAddresses();
      await this.collectBasicMetadata();
      await this.collectAdvancedMetadata();

      this.showSummary();

      const confirmed = await this.confirmConfiguration();
      if (!confirmed) {
        this.log('Configuration cancelled.', 'red');
        process.exit(1);
      }

      this.generateConfigFiles();
      await this.handleDeployment();

      this.log('Configuration completed!', 'green');
    } catch (error) {
      if (error instanceof Error && error.message === 'Input stream closed') {
        // User cancelled with Ctrl+C or closed input
        console.log('\n');
        this.log('Operation cancelled by user.', 'yellow');
        process.exit(0);
      } else {
        this.log(`Error: ${error}`, 'red');
        process.exit(1);
      }
    } finally {
      this.rl.close();
    }
  }
}

// Main execution
if (require.main === module) {
  const initializer = new EVVMInitializer();
  initializer.run().catch((error) => {
    console.error('Unhandled error:', error);
    process.exit(1);
  });
}

export { EVVMInitializer };