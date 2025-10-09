#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Colores para la salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GRAY='\033[0;90m'
EVVM_GREEN='\033[38;2;1;240;148m'
NC='\033[0m' # No Color

# Banner
echo -e "${EVVM_GREEN}"
echo "░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░  "
echo "░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ "
echo "░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ " 
echo "░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ "
echo "░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ "
echo "░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ "
echo "░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ "
echo -e "${NC}"

# Crear directorio input si no existe
mkdir -p input

echo -e "${YELLOW}Configuring deployment variables...${NC}\n"

# Function to validate Ethereum addresses
validate_address() {
    if [[ $1 =~ ^0x[a-fA-F0-9]{40}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate numbers
validate_number() {
    if [[ $1 =~ ^[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Gather information
echo -e "${GREEN}=== Administrator Configuration ===${NC}"

while true; do
    read -p "Admin address (0x...): " admin
    if validate_address "$admin"; then
        break
    else
        echo -e "${RED}Error: Invalid address. Must be a valid Ethereum address (0x + 40 hex characters)${NC}"
    fi
done

while true; do
    read -p "Golden Fisher address (0x...): " goldenFisher
    if validate_address "$goldenFisher"; then
        break
    else
        echo -e "${RED}Error: Invalid address. Must be a valid Ethereum address (0x + 40 hex characters)${NC}"
    fi
done

while true; do
    read -p "Activator address (0x...): " activator
    if validate_address "$activator"; then
        break
    else
        echo -e "${RED}Error: Invalid address. Must be a valid Ethereum address (0x + 40 hex characters)${NC}"
    fi
done

echo -e "${GREEN}=== EVVM Metadata Configuration ===${NC}"

read -p "$(echo -e "EVVM Name ${GRAY}[EVVM]${NC}: ")" evvmName
evvmName=${evvmName:-"EVVM"}

read -p "$(echo -e "Principal Token Name ${GRAY}[Mate token]${NC}: ")" principalTokenName
principalTokenName=${principalTokenName:-"Mate token"}

read -p "$(echo -e "Principal Token Symbol ${GRAY}[MATE]${NC}: ")" principalTokenSymbol
principalTokenSymbol=${principalTokenSymbol:-"MATE"}

echo -e "\n${BLUE}=== Advanced Configuration (Optional) ===${NC}"
read -p "$(echo -e "Do you want to configure advanced metadata? (y/n) ${GRAY}[n]${NC}: ")" configAdvanced
configAdvanced=${configAdvanced:-"n"}

if [[ $configAdvanced == "y" || $configAdvanced == "Y" ]]; then
    while true; do
        read -p "$(echo -e "Total Supply ${GRAY}[2033333333000000000000000000]${NC}: ")" totalSupply
        totalSupply=${totalSupply:-"2033333333000000000000000000"}
        if validate_number "$totalSupply"; then
            break
        else
            echo -e "${RED}Error: Must be a valid number${NC}"
        fi
    done

    while true; do
        read -p "$(echo -e "Era Tokens ${GRAY}[1016666666500000000000000000]${NC}: ")" eraTokens
        eraTokens=${eraTokens:-"1016666666500000000000000000"}
        if validate_number "$eraTokens"; then
            break
        else
            echo -e "${RED}Error: Must be a valid number${NC}"
        fi
    done

    while true; do
        read -p "$(echo -e "Reward per operation ${GRAY}[5000000000000000000]${NC}: ")" reward
        reward=${reward:-"5000000000000000000"}
        if validate_number "$reward"; then
            break
        else
            echo -e "${RED}Error: Must be a valid number${NC}"
        fi
    done
else
    # Default values
    totalSupply="2033333333000000000000000000"
    eraTokens="1016666666500000000000000000"
    reward="5000000000000000000"
    echo -e "${YELLOW}Using default advanced values${NC}"
fi

# Show summary
echo -e "\n${YELLOW}=== Configuration Summary ===${NC}"
echo -e "Admin: ${GREEN}$admin${NC}"
echo -e "Golden Fisher: ${GREEN}$goldenFisher${NC}"
echo -e "Activator: ${GREEN}$activator${NC}"
echo -e "EVVM Name: ${GREEN}$evvmName${NC}"
echo -e "Principal Token Name: ${GREEN}$principalTokenName${NC}"
echo -e "Principal Token Symbol: ${GREEN}$principalTokenSymbol${NC}"
echo -e "Total Supply: ${GREEN}$totalSupply${NC}"
echo -e "Era Tokens: ${GREEN}$eraTokens${NC}"
echo -e "Reward: ${GREEN}$reward${NC}"

echo ""
read -p "Is the data correct? (y/n): " confirm

if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo -e "${RED}Configuration cancelled.${NC}"
    exit 1
fi

# Generate JSON files
# Address file
cat > input/address.json << EOF
{
  "admin": "$admin",
  "goldenFisher": "$goldenFisher",
  "activator": "$activator"
}
EOF

# Basic metadata file
cat > input/evvmBasicMetadata.json << EOF
{
  "EvvmName": "$evvmName",
  "principalTokenName": "$principalTokenName",
  "principalTokenSymbol": "$principalTokenSymbol"
}
EOF

# Advanced metadata file
cat > input/evvmAdvancedMetadata.json << EOF
{
  "totalSupply": $totalSupply,
  "eraTokens": $eraTokens,
  "reward": $reward
}
EOF

echo -e "${GREEN}✅ Configuration files generated:${NC}"
echo -e "   - input/address.json"
echo -e "   - input/evvmBasicMetadata.json"
echo -e "   - input/evvmAdvancedMetadata.json"

# Ask if they want to deploy immediately
echo ""
read -p "Do you want to deploy the contracts now? (y/n): " deployNow

if [[ $deployNow == "y" || $deployNow == "Y" ]]; then
    echo -e "${GREEN}=== Network Selection ===${NC}"
    echo "Available networks:"
    echo "  eth    - Ethereum Sepolia"
    echo "  arb    - Arbitrum Sepolia"
    echo "  custom - Custom RPC URL"
    echo ""
    
    while true; do
        read -p "$(echo -e "Select network (eth/arb/custom) ${GRAY}[eth]${NC}: ")" network
        network=${network:-"eth"}
        
        if [[ $network == "eth" || $network == "arb" || $network == "custom" ]]; then
            break
        else
            echo -e "${RED}Error: Invalid network. Use 'eth', 'arb', or 'custom'${NC}"
        fi
    done
    
    if [[ $network == "custom" ]]; then
        echo -e "${BLUE}=== Custom Network Configuration ===${NC}"
        while true; do
            read -p "Enter RPC URL: " rpc_url
            if [[ -n "$rpc_url" ]]; then
                break
            else
                echo -e "${RED}Error: RPC URL is required${NC}"
            fi
        done
        
        echo -e "${BLUE}Starting deployment on custom network...${NC}"
        forge script script/DeployTestnet.s.sol:DeployTestnet \
            --rpc-url "$rpc_url" \
            --account defaultKey \
            --broadcast \
            --verify \
            --etherscan-api-key $ETHERSCAN_API \
            -vvvvvv
    else
        echo -e "${BLUE}Starting deployment on ${network}...${NC}"
        make deployTestnet NETWORK=$network
    fi
else
    echo -e "${YELLOW}To deploy later, run:${NC}"
    echo -e "  ${YELLOW}For predefined networks: make deployTestnet NETWORK=<eth|arb>${NC}"
    echo -e "  ${YELLOW}For custom RPC: forge script script/DeployTestnet.s.sol:DeployTestnet --rpc-url <YOUR_RPC_URL> --account defaultKey --broadcast --verify --etherscan-api-key \$ETHERSCAN_API -vvvvvv${NC}"
fi

echo -e "${GREEN}Configuration completed!${NC}"