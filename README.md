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
- `script/` — Deployment and automation scripts (e.g., `DeployTestnet.s.sol`)
- `lib/` — External dependencies (OpenZeppelin, Uniswap v3, forge-std)
- `broadcast/` — Foundry deployment artifacts and transaction history
- `cache/` — Foundry compilation cache
- `input/` — Configuration files for deployment (generated by `evvm-init.sh`)
- `evvm-init.sh` — Interactive setup and deployment script

## Prerequisites
- [Foundry](https://getfoundry.sh/) (Solidity development toolkit)
- Node.js (if using npm installation method)
- Bash shell (for running `evvm-init.sh`)
- Environment variables set up (`.env` file with API keys and RPC URLs)

### Environment Setup
Create a `.env` file with your configuration:
```bash
RPC_URL_ETH_SEPOLIA=<YOUR_ETH_SEPOLIA_RPC_URL>
RPC_URL_ARB_SEPOLIA=<YOUR_ARB_SEPOLIA_RPC_URL>
ETHERSCAN_API=<YOUR_ETHERSCAN_API_KEY>
```

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
./evvm-init.sh
```

The wizard will configure:
- **Administrator addresses** (admin, golden fisher, activator)
- **EVVM metadata** (name, ID, principal token details)
- **Advanced parameters** (supply, rewards) - optional
- **Network selection** (Ethereum Sepolia, Arbitrum Sepolia, or custom)
- **Automatic deployment** with contract verification

That's it! Your EVVM virtual blockchain is now deployed and verified on your chosen host blockchain.

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
- `evvm-init.sh` — Interactive setup wizard
- `input/` — Generated configuration files (address.json, evvmBasicMetadata.json, evvmAdvancedMetadata.json)
- `foundry.toml` — Foundry project configuration
- `makefile` — Build and deployment automation

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
