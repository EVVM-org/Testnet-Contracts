-include .env

.PHONY: all install compile anvil help

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Network Arguments
ANVIL_ARGS := --rpc-url http://localhost:8545 \
              --private-key $(DEFAULT_ANVIL_KEY) \
              --broadcast \
              --via-ir

ARB_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ARB_SEPOLIA) \
                            --account defaultKey \
                            --broadcast \
                            --verify \
                            --etherscan-api-key $(ETHERSCAN_API) \

ETH_SEPOLIA_TESTNET_ARGS := --rpc-url $(RPC_URL_ETH_SEPOLIA) \
                            --account defaultKey \
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

deployRegistryEvvm: 
	@echo "Deploying RegistryEvvm contract on Ethereum Sepolia"
	@forge clean
	@forge script script/DeployRegistryEvvm.s.sol:DeployRegistryEvvm $(ETH_SEPOLIA_TESTNET_ARGS) -vvvvvv

# Help command
help:
	@echo "-------------------------------------=Usage=-------------------------------------"
	@echo ""
	@echo "  make install -- Install dependencies and compile contracts"
	@echo "  make compile -- Compile contracts"
	@echo "  make anvil ---- Run Anvil (local testnet)"
	@echo ""
	@echo "-----------------------=Deployers for local testnet (Anvil)=----------------------"
	@echo ""
	@echo "  make deployLocalTestnet ----------- Deploy local testnet contracts"
	@echo ""
	@echo "-----------------------=Deployers for test networks=----------------------"
	@echo ""
	@echo "  make deployTestnet ---------------- Deploy testnet contracts"
	@echo ""
	@echo "-----------------------=Deployer for RegistryEvvm=----------------------"
	@echo ""
	@echo "  make deployRegistryEvvm ----------- Deploy RegistryEvvm contract on Ethereum Sepolia"
	@echo ""
	@echo "---------------------------------------------------------------------------------"