# EVVM Testnet Contracts

EVVM is an innovative blockchain virtualization system that allows you to create and deploy your own virtual blockchains on top of existing Ethereum networks where you can:

- **Create your own virtual blockchain** with custom tokens and governance
- **Deploy on testnets** like Ethereum Sepolia or Arbitrum Sepolia for testing
- **Use proven, audited contracts** for staking, treasury management, and domain services
- **Scale to mainnet** when ready for production

## What's included?

EVVM provides a complete ecosystem of smart contracts:
- **Core EVVM**: Your virtual blockchain's main engine
- **NameService**: Domain name system for your blockchain (like ENS)
- **Staking**: Token staking and rewards system
- **Treasury**: Secure fund management inside the host chain or across chains
- **Estimator**: Reward calculation and optimization
- **P2PSwap**: Peer-to-peer token exchange service with automated market making

## Latest Features

**Enhanced Deployment Experience:**
- **Interactive TypeScript Wizard**: Modern, user-friendly deployment wizard with comprehensive guidance
- **Automatic RPC Fallback**: 99%+ deployment success rate with 5 fallback RPCs per network
- **Deployment Summary**: Instant access to all deployed contract addresses with explorer links
- **Auto Registry Integration**: Automatic EVVM registration and ID configuration
- **Smart Prerequisites Check**: Automatic dependency initialization and validation
- **Multi-Wallet Support**: Easy selection from your Foundry keystores

**Reliability Improvements:**
- Intelligent retry mechanism for network failures
- Comprehensive error handling and troubleshooting guides
- Verified high-performance RPC endpoints
- Zero-configuration setup for most users

## Use Cases

This repository serves two main purposes:

### Deploy Your Own EVVM Instance
Create and deploy a complete virtual blockchain with all EVVM contracts on testnets for experimentation and testing.

### Build Services Using Existing EVVM
Use EVVM contracts as a library to build services that interact with already deployed EVVM instances.

---

## Quick Start Options

Choose your path based on what you want to achieve:

### Option A: Building Services on Existing EVVM 

**Perfect if you want to create smart contracts that interact with already deployed EVVM instances.**

Simply install the library and start building:

```bash
# Install via NPM
npm install @evvm/testnet-contracts

# OR install via Forge  
forge install EVVM-org/Testnet-Contracts
```

**What you get**: Access to all EVVM interfaces and contracts to build services that interact with live EVVM instances on testnets.

**Next steps**: Jump to [Library Usage](#library-usage) section below.

### Option B: Deploy Your Own Complete EVVM Instance

**Perfect if you want to create your own virtual blockchain with custom tokens and governance.**

Follow the complete deployment process:

**What you get**: Your own virtual blockchain with custom tokens, domain system, staking rewards, and treasury management - all deployed and verified on public testnets.

**Next steps**: Jump to [Deploy Your Own EVVM](#deploy-your-own-evvm) section below.

---

## Library Usage

> **For Building Services**: This section is for developers who want to build smart contracts that interact with existing EVVM instances. If you want to deploy your own complete EVVM instance, skip to [Deploy Your Own EVVM](#deploy-your-own-evvm).

This repository can be used as a library in your Solidity projects through multiple installation methods:

### Installation Options

#### Option 1: NPM
```bash
npm install @evvm/testnet-contracts
```

#### Option 2: Forge
```bash
forge install EVVM-org/Testnet-Contracts
```

### Configuration

#### If using NPM installation
Add to your `foundry.toml`:
```toml
remappings = [
    "@evvm/testnet-contracts/=node_modules/@evvm/testnet-contracts/src/",
]
```

#### If using Forge installation
Add to your `foundry.toml`:
```toml
remappings = [
    "@evvm/testnet-contracts/=lib/Testnet-Contracts/src/",
]
```

### Package Structure

```
@evvm/testnet-contracts/
├── src/
│   ├── contracts/
│   │   ├── evvm/Evvm.sol           # Core EVVM implementation
│   │   ├── nameService/NameService.sol  # Domain name resolution
│   │   ├── staking/Staking.sol     # Staking mechanism
│   │   ├── staking/Estimator.sol   # Rewards estimation
│   │   ├── treasury/Treasury.sol   # Treasury management
│   │   ├── treasuryTwoChains/      # Cross-chain treasury contracts
│   │   └── p2pSwap/P2PSwap.sol     # Peer-to-peer token exchange
│   ├── interfaces/                 # All contract interfaces
│   └── lib/                       # Utility libraries
```

### Quick Integration Example

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import "@evvm/testnet-contracts/interfaces/ITreasury.sol";

contract MyDApp {
    IEvvm public immutable evvm;
    ITreasury public immutable treasury;
    
    constructor(address _evvm, address _treasury) {
        evvm = IEvvm(_evvm);
        treasury = ITreasury(_treasury);
    }
    
    function getEvvmInfo() external view returns (string memory name, uint256 id) {
        name = evvm.getEvvmName();
        id = evvm.getEvvmID();
    }
}
```

### Available Contracts

#### Core Contracts
- `contracts/evvm/Evvm.sol` - Main EVVM virtual machine implementation
- `contracts/nameService/NameService.sol` - Domain name resolution system
- `contracts/staking/Staking.sol` - Token staking and rewards mechanism
- `contracts/staking/Estimator.sol` - Staking rewards estimation and calculation
- `contracts/treasury/Treasury.sol` - Manages deposits and withdrawals
- `contracts/p2pSwap/P2PSwap.sol` - Peer-to-peer decentralized token exchange service

#### Cross-chain Treasury
- `contracts/treasuryTwoChains/TreasuryHostChainStation.sol` - Host chain treasury management
- `contracts/treasuryTwoChains/TreasuryExternalChainStation.sol` - External chain treasury management

#### Interfaces
All contracts have corresponding interfaces in the `interfaces/` directory:
- `interfaces/IEvvm.sol`
- `interfaces/INameService.sol`
- `interfaces/IStaking.sol`
- `interfaces/IEstimator.sol`
- `interfaces/ITreasury.sol`
- `interfaces/ITreasuryHostChainStation.sol`
- `interfaces/ITreasuryExternalChainStation.sol`
- `interfaces/IP2PSwap.sol`

#### Utility Libraries
- `lib/AdvancedStrings.sol` - Advanced string manipulation utilities
- `lib/SignatureRecover.sol` - Signature recovery utilities
- `lib/Erc191TestBuilder.sol` - ERC-191 signature testing utilities
- `lib/StakingServiceHooks.sol` - Simplified staking integration for service contracts

### Import Patterns

#### Individual Contract Imports
```solidity
import "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import "@evvm/testnet-contracts/lib/AdvancedStrings.sol";
```

#### Interface-Only Imports (Recommended for DApps)
```solidity
import "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import "@evvm/testnet-contracts/interfaces/IStaking.sol";
```

### Dependencies

#### If using NPM installation
Dependencies are automatically handled when you install the package. However, you need to ensure you have the peer dependencies:

```bash
npm install @openzeppelin/contracts
```

For cross-chain functionality, you might also need:
```bash
npm install @hyperlane-xyz/core
```

#### If using Forge installation
You need to manually install all dependencies:

```bash
forge install OpenZeppelin/openzeppelin-contracts
forge install hyperlane-xyz/hyperlane-monorepo  # For cross-chain functionality
```

## Repository Structure
- `src/contracts/evvm/` — Core EVVM contracts and storage
- `src/contracts/nameService/` — NameService contracts for domain management
- `src/contracts/staking/` — Staking and Estimator contracts
- `src/contracts/treasury/` — Treasury contract for managing deposits and withdrawals
- `src/contracts/p2pSwap/` — P2P token exchange service contracts
- `src/lib/` — Shared Solidity libraries (AdvancedStrings, SignatureRecover, etc.)
- `script/` — Foundry deployment scripts (e.g., `DeployTestnet.s.sol`)
- `scripts/` — TypeScript utilities and deployment wizard (`evvm-init.ts`)
- `lib/` — External dependencies (OpenZeppelin, Uniswap v3, forge-std)
- `broadcast/` — Foundry deployment artifacts and transaction history
- `cache/` — Foundry compilation cache
- `input/` — Configuration files for deployment (generated by wizard)
- `evvm-init.sh` — Legacy bash wizard (deprecated, use `npm run wizard` instead)

## Prerequisites
- [Foundry](https://getfoundry.sh/) (Solidity development toolkit)
- [Node.js](https://nodejs.org/) v16 or higher (required for deployment wizard)
- Git (for cloning and managing the repository)
- Environment variables set up (`.env` file with API keys and RPC URLs)

### Environment Setup
Create a `.env` file with your configuration:
```bash
# Ethereum Sepolia RPC (primary endpoint)
RPC_URL_ETH_SEPOLIA=https://0xrpc.io/sep

# Arbitrum Sepolia RPC (primary endpoint)
RPC_URL_ARB_SEPOLIA=https://sepolia-rollup.arbitrum.io/rpc

# Etherscan API key for contract verification
ETHERSCAN_API=<YOUR_ETHERSCAN_API_KEY>
```

**Note**: The deployment wizard includes automatic RPC fallback mechanisms. If your primary RPC endpoint fails, it will automatically try alternative endpoints to ensure deployment success. See the [RPC Reliability](#rpc-reliability) section for details.

### Security Setup - Import Private Key
Before deploying to testnets, securely import your private key using Foundry:
```bash
cast wallet import defaultKey --interactive
```
This command will prompt you to enter your private key securely. The key will be encrypted and stored locally by Foundry.

> **Note**: `defaultKey` is the default alias used in the makefile and deployment scripts. If you prefer to use a different alias, simply replace `defaultKey` with your chosen name in both the import command and update the corresponding references in the makefile and scripts.

> **Security Note**: Never commit real private keys to version control. Always use the secure wallet import method above for testnet and mainnet deployments.

## Key Dependencies
- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)

## Deploy Your Own EVVM

Want to create your own virtual blockchain? Follow these steps to deploy a complete EVVM instance on testnets:

> **What you'll get**: Your own virtual blockchain with custom tokens, domain system, staking rewards, and treasury management - all deployed and verified on public testnets.

### 1. Clone and Install
```bash
git clone https://github.com/EVVM-org/Testnet-Contracts
cd Testnet-Contracts
make install
```

### 2. Environment Setup
Create `.env` file with your configuration:
```bash
cp .env.example .env
# Add your RPC URLs and API keys
```

### 3. Secure Key Import
```bash
cast wallet import defaultKey --interactive
```

### 4. Interactive Setup & Deploy
```bash
npm run wizard
```

The interactive deployment wizard will guide you through:
- **Prerequisites check** (Foundry, Git, Node.js)
- **Dependency initialization** (git submodules - automatic)
- **Administrator addresses** (admin, golden fisher, activator)
- **EVVM metadata** (name, principal token details)
- **Advanced parameters** (supply, rewards) - optional
- **Network selection** (Ethereum Sepolia, Arbitrum Sepolia, or custom RPC)
- **Wallet selection** (from your Foundry keystores)
- **Automatic deployment** with contract verification
- **Deployment summary** with all contract addresses and explorer links
- **Registry EVVM registration** (automatic for supported networks)
- **EVVM ID configuration** (automatic setup)

**What happens after deployment:**
- All 6 core contracts deployed and verified on your chosen network
- Complete deployment summary displayed with:
  - EVVM Core contract address
  - Treasury contract address
  - Staking, Estimator, NameService, and P2PSwap addresses
  - Direct links to block explorer for each contract
- Automatic registration with Registry EVVM (Ethereum Sepolia)
- EVVM ID assigned and configured

That's it! Your EVVM virtual blockchain is now deployed, verified, and ready to use.

## Manual Configuration (Alternative)

If you prefer manual control over configuration, create these files in `input/`:

**input/address.json**:
```json
{
  "admin": "0x...",
  "goldenFisher": "0x...",
  "activator": "0x..."
}
```

**input/evvmBasicMetadata.json**:
```json
{
  "EvvmName": "EVVM",
  "EvvmID": 1,
  "principalTokenName": "Mate token",
  "principalTokenSymbol": "MATE"
}
```

**input/evvmAdvancedMetadata.json**:
```json
{
  "totalSupply": 2033333333000000000000000000,
  "eraTokens": 1016666666500000000000000000,
  "reward": 5000000000000000000
}
```

## Local Development & Manual Deployment

### Start Local Development
```bash
make anvil                # Start local blockchain
make deployLocalTestnet   # Deploy to local chain
```

### Manual Deployment to Testnets

If you prefer to deploy manually after configuration:

```bash
# Ethereum Sepolia
make deployTestnet NETWORK=eth

# Arbitrum Sepolia  
make deployTestnet NETWORK=arb

# Custom RPC
forge script script/DeployTestnet.s.sol:DeployTestnet \
    --rpc-url <YOUR_RPC_URL> \
    --account defaultKey \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API
```

## Development Commands
```bash
make install     # Install dependencies and compile
make compile     # Recompile contracts
make seeSizes    # Check contract sizes
make help        # Show all available commands
```

### NPM Scripts
```bash
npm run wizard           # Run interactive deployment wizard (recommended)
npm run build           # Copy src/ files to root (for NPM publishing)
npm run clean           # Remove copied files from root
npm run compile         # forge build
npm run test            # forge test
npm run deploy:anvil    # Deploy to local Anvil
npm run deploy:sepolia  # Deploy to Ethereum Sepolia
npm run deploy:arbitrum # Deploy to Arbitrum Sepolia
```

## RPC Reliability

The deployment wizard includes an intelligent RPC fallback mechanism to ensure maximum deployment success rates, even when individual RPC providers experience downtime.

### How It Works

**Automatic Failover**: If your primary RPC endpoint fails, the wizard automatically tries alternative endpoints without user intervention.

**Multi-Provider Support**: Each network has 5 verified RPC endpoints:

**Ethereum Sepolia Fallback Chain:**
1. `https://0xrpc.io/sep` (Primary)
2. `https://ethereum-sepolia.rpc.subquery.network/public` (0.165s latency)
3. `https://ethereum-sepolia.gateway.tatum.io` (0.172s latency)
4. `https://sepolia.drpc.org` (0.192s latency)
5. `https://gateway.tenderly.co/public/sepolia` (0.184s latency)

**Arbitrum Sepolia Fallback Chain:**
1. `https://sepolia-rollup.arbitrum.io/rpc` (Official Arbitrum)
2. `https://arbitrum-sepolia.gateway.tenderly.co` (0.167s latency)
3. `https://endpoints.omniatech.io/v1/arbitrum/sepolia/public` (0.258s latency)
4. `https://arbitrum-sepolia.drpc.org` (0.590s latency)
5. `https://arbitrum-sepolia-rpc.publicnode.com` (0.430s latency)

**Smart Retry Logic**: The wizard displays clear progress messages during fallback attempts and provides troubleshooting tips if all endpoints fail.

### Benefits
- **99%+ success rate** through endpoint redundancy
- **Zero configuration** required for most users
- **Automatic recovery** from individual RPC failures
- **Clear visibility** into which RPC is being used
- **Future-proof** against provider outages

## Deployment Summary

After successful deployment, the wizard displays a comprehensive summary of all deployed contracts:

```
═══════════════════════════════════════════════════════════
                 DEPLOYED CONTRACTS SUMMARY
═══════════════════════════════════════════════════════════

Network: Ethereum Sepolia (Chain ID: 11155111)

Core Contracts:
  EVVM:        0xb0994626541c9bd3d64605dee610386c7a005a39
               https://sepolia.etherscan.io/address/0xb099...
  Treasury:    0x47be342c4d803490530737cac7bcf34916cf7e80
               https://sepolia.etherscan.io/address/0x47be...

Supporting Contracts:
  Staking:     0xc2cd4ec40bb4fa6f98c7b7095f692588e6b68fd4
  Estimator:   0x1adf3fd08f0744f24bb29bbfcfb57a5f37f144cb
  NameService: 0xe28eedff481b7c640394f44070309a0afe06de00
  P2PSwap:     0xc90dc57d848fae4ecf46268b8a90015085968645

═══════════════════════════════════════════════════════════
```

This summary includes:
- Network name and chain ID
- All 6 deployed contract addresses
- Direct links to block explorer for verification
- Organized by contract importance (Core vs Supporting)

## Troubleshooting

### RPC Connection Issues

**Problem**: Deployment fails with "Connection timed out" or "HTTP error 522"

**Solution**: The wizard automatically tries fallback RPCs. If all fail:
1. Check your internet connection
2. Verify firewall/VPN settings aren't blocking RPC endpoints
3. Try again later (temporary provider downtime)
4. Update your `.env` file with a custom RPC from [chainlist.org](https://chainlist.org/)

### Wallet Not Found

**Problem**: "No wallets found" error during deployment

**Solution**:
```bash
cast wallet import <WALLET_NAME> --interactive
```
Then run the wizard again and select your imported wallet.

### Insufficient Funds

**Problem**: Deployment fails with "insufficient funds for gas"

**Solution**:
1. Get testnet ETH from faucets:
   - Ethereum Sepolia: [sepoliafaucet.com](https://sepoliafaucet.com/)
   - Arbitrum Sepolia: [faucet.quicknode.com/arbitrum/sepolia](https://faucet.quicknode.com/arbitrum/sepolia)
2. Verify your wallet address has received funds
3. Run the wizard again

### Git Submodules Not Initialized

**Problem**: Compilation fails with missing dependencies

**Solution**: The wizard automatically initializes submodules, but you can also do it manually:
```bash
git submodule update --init --recursive
```

### Contract Size Too Large

**Problem**: "Contract code size exceeds 24576 bytes"

**Solution**: The project uses `via-ir` optimization to stay under limits. If you modified contracts:
```bash
make seeSizes  # Check contract sizes
```
Consider refactoring large contracts or using libraries.

### TypeScript/TSX Not Found

**Problem**: `npm run wizard` fails with "tsx: command not found"

**Solution**:
```bash
npm install  # Reinstall dependencies
```

## Contract Architecture
The EVVM ecosystem consists of six main contracts:
- **Evvm.sol**: Core virtual machine implementation
- **NameService.sol**: Domain name resolution system  
- **Staking.sol**: Token staking and rewards mechanism
- **Estimator.sol**: Staking rewards estimation and calculation
- **Treasury.sol**: Manages deposits and withdrawals of ETH and ERC20 tokens
- **P2PSwap.sol**: Peer-to-peer decentralized exchange for token trading


## Configuration Files
Key files for EVVM deployment:
- `scripts/evvm-init.ts` — Interactive TypeScript deployment wizard (run with `npm run wizard`)
- `input/` — Generated configuration files (address.json, evvmBasicMetadata.json, evvmAdvancedMetadata.json)
- `.env` — Environment variables (RPC URLs, API keys)
- `foundry.toml` — Foundry project configuration
- `makefile` — Build and deployment automation
- `package.json` — NPM scripts and dependencies

## Contributing

**Development Flow Context**: This repository is the next step after successful playground testing. It is dedicated to advanced integration, deployment, and validation on public testnets, before mainnet implementation.

### Development Flow
1. **Playground**: Prototype and experiment with new features in the playground repo.
2. **Testnet (this repo)**: Integrate, test, and validate on public testnets.
3. **Mainnet**: After successful testnet validation, proceed to mainnet deployment.

### How to Contribute
1. Fork the repository
2. Create a feature branch and make changes
3. Add tests for new features
4. Submit a PR with a detailed description

## Security Best Practices
- **Never commit private keys**: Always use `cast wallet import <YOUR_ALIAS> --interactive` to securely store your keys
- **Use test credentials only**: This repository is for testnet deployment only
- **Environment variables**: Store sensitive data like API keys in `.env` files (not committed to git)
- **Verify contracts**: Always verify your deployed contracts on block explorers
