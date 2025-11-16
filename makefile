-include .env

.PHONY: all install compile anvil wizard help

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
WALLET ?= defaultKey

# Network Arguments
ANVIL_ARGS := --rpc-url http://localhost:8545 \
              --private-key $(DEFAULT_ANVIL_KEY) \
              --broadcast \
              --via-ir

ARB_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ARB_SEPOLIA) \
                            --account $(WALLET) \
                            --broadcast \
                            --verify \
                            --etherscan-api-key $(ETHERSCAN_API) \

ETH_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ETH_SEPOLIA) \
                            --account $(WALLET) \
                            --broadcast \
                            --verify \
                            --etherscan-api-key $(ETHERSCAN_API) \

# Main commands
all: clean remove install update build 

install:
	@echo "Installing libraries"
	@npm install
	@forge compile --via-ir

compile:
	@forge b --via-ir

seeSizes:
	@forge b --via-ir --sizes

anvil:
	@echo "Starting Anvil, remember to use another terminal to run tests"
	@anvil -m 'test test test test test test test test test test test junk' --block-time 10

wizard:
	@echo "Starting EVVM Configuration Wizard"
	@sh evvm-init.sh

deployTestnet: 
	@echo "Deploying testnet on $(NETWORK)"
	@forge clean
	@if [ "$(NETWORK)" = "eth" ]; then \
		forge script script/DeployTestnet.s.sol:DeployTestnet $(ETH_SEPOLIA_TESTNET_ARGS) -vvvvvv; \
	elif [ "$(NETWORK)" = "arb" ] || [ -z "$(NETWORK)" ]; then \
		forge script script/DeployTestnet.s.sol:DeployTestnet $(ARB_SEPOLIA_TESTNET_ARGS) -vvvvvv; \
	else \
		echo "Unknown network: $(NETWORK). Use 'eth' or 'arb'"; exit 1; \
	fi

deployTestnetCrossChainHost: 
	@echo "Deploying contracts on host chain (ETH Sepolia)"
	@forge clean
	@forge script script/DeployTestnetCrossChain.s.sol:DeployTestnetCrossChain $(ETH_SEPOLIA_TESTNET_ARGS) -vvvvvv
	
deployTestnetCrossChainExternal:
	@echo "Deploying contracts on remote chain (Arbitrum Sepolia)"
	@forge clean
	@forge script script/DeployTestnetCrossChain.s.sol:DeployTestnetCrossChain $(ARB_SEPOLIA_TESTNET_ARGS) -vvvvvv

deployTestnetAnvil: 
	@echo "Deploying local testnet"
	@forge clean
	@forge script script/DeployTestnetOnAnvil.s.sol:DeployTestnetOnAnvil $(ANVIL_ARGS) -vvvv
# Help command
help:
	@echo "================================================================================="
	@echo "                           EVVM Testnet Contracts - Makefile"
	@echo "================================================================================="
	@echo ""
	@echo "============================= Basic Commands =================================="
	@echo ""
	@echo "  make all ----------- Clean, remove, install, update and build all contracts"
	@echo "  make install ------- Install npm dependencies and compile contracts with via-ir"
	@echo "  make compile ------- Build contracts using forge with via-ir optimization"
	@echo "  make seeSizes ------ Display contract sizes after compilation"
	@echo "  make anvil --------- Start Anvil local testnet (use another terminal for tests)"
	@echo "  make wizard -------- Launch EVVM configuration wizard (evvm-init.sh)"
	@echo ""
	@echo "========================== Deployment Commands ============================="
	@echo ""
	@echo "  make deployTestnet NETWORK=<eth|arb> -- Deploy testnet contracts"
	@echo "                                          Default: arb (Arbitrum Sepolia)"
	@echo "                                          Options: eth (Ethereum Sepolia)"
	@echo ""
	@echo "  make deployTestnetAnvil -------------- Deploy contracts on local Anvil testnet"
	@echo ""
	@echo "======================== Cross-Chain Deployments ============================"
	@echo ""
	@echo "  make deployTestnetCrossChainHost ----- Deploy contracts on host chain (ETH Sepolia)"
	@echo "  make deployTestnetCrossChainExternal - Deploy contracts on remote chain (ARB Sepolia)"
	@echo ""
	@echo "========================== Registry Deployment ============================="
	@echo ""
	@echo "  make deployRegistryEvvm -------------- Deploy RegistryEvvm contract (ETH Sepolia)"
	@echo ""
	@echo "================================= Examples ===================================="
	@echo ""
	@echo "  make deployTestnet NETWORK=eth ------- Deploy to Ethereum Sepolia"
	@echo "  make deployTestnet NETWORK=arb ------- Deploy to Arbitrum Sepolia"
	@echo "  make deployTestnet ----------------- Deploy to Arbitrum Sepolia (default)"
	@echo ""
	@echo "================================== Notes ====================================="
	@echo ""
	@echo "  - All testnet deployments require proper .env configuration"
	@echo "  - Cross-chain deployments should be done in sequence (host first, then external)"
	@echo "  - Anvil deployments use default test keys and local RPC"
	@echo ""
	@echo "================================================================================="