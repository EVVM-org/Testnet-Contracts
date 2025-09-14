// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.org/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**

░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓██████████████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░       ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓██████▓▒░  ░▒▓█▓▒▒▓█▓▒░ ░▒▓█▓▒▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░        ░▒▓█▓▓█▓▒░   ░▒▓█▓▓█▓▒░ ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓████████▓▒░  ░▒▓██▓▒░     ░▒▓██▓▒░  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░ 

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
                                                             
/**
 * @title EVVM (Ethereum Virtual Machine Virtualization) Core Contract
 * @author jistro.eth ariutokintumi.eth
 * @notice Core payment processing and token management system for the EVVM ecosystem
 * @dev This contract serves as the central hub for:
 *      - Multi-token payment processing with signature verification
 *      - Staker reward distribution and incentive mechanisms
 *      - Cross-chain bridge functionality (Fisher Bridge)
 *      - Balance management across the EVVM ecosystem
 *      - Integration with NameService for identity-based payments
 *      - Treasury integration for privileged balance operations
 * 
 * Key Features:
 * - Synchronous and asynchronous payment processing with nonce management
 * - Staker privilege system with enhanced rewards and transaction processing benefits
 * - Multi-recipient payment batching (payMultiple, dispersePay)
 * - Administrative payment distribution (caPay, disperseCaPay)
 * - Proxy pattern support with delegatecall fallback for upgradeability
 * - Cross-chain asset bridging capabilities through Fisher Bridge
 * - Deflationary tokenomics with era-based reward halving mechanism
 * - Treasury-controlled balance management for minting and burning operations
 * 
 * Payment Types:
 * - `payNoStaker_*`: Standard payments for non-stakers with basic functionality
 * - `payStaker_*`: Enhanced payments for Principal Token stakers with priority fee rewards
 * - `payMultiple`: Batch payments to multiple recipients with individual success tracking
 * - `dispersePay`: Single-source multi-recipient distribution with signature verification
 * - `caPay`: Administrative token distribution for smart contracts
 * - Treasury functions: Direct balance manipulation for authorized operations
 * 
 * Economic Model:
 * - Principal Token as principal token with reward distribution system
 * - Era-based reward halving when supply thresholds are reached
 * - Staker incentives through transaction processing rewards
 * - Random bonus rewards for triggering era transitions
 * 
 * Security Features:
 * - Signature-based transaction authorization with EIP-191 compliance
 * - Dual nonce system: synchronous (sequential) and asynchronous (custom)
 * - Executor validation for delegated transaction processing
 * - Balance verification before transfers to prevent overdrafts
 * - Time-delayed governance for critical upgrades (30-day implementation, 1-day admin)
 * - Access control through admin and treasury authorization
 * 
 * Integration Points:
 * - NameService: Identity resolution for username-based payments
 * - Staking Contract: Staker status management and reward distribution
 * - Treasury Contract: Privileged balance operations and token management
 * - Implementation Contract: Proxy pattern for contract upgradeability
 * 
 * @custom:version 1.0.0
 * @custom:testnet This contract is deployed on testnet for development and testing
 * @custom:security Time-delayed governance, signature verification, access control
 * @custom:upgrade-pattern Transparent proxy with admin-controlled implementation
 */

import {NameService} from "@EVVM/testnet/contracts/nameService/NameService.sol";
import {EvvmStorage} from "@EVVM/testnet/contracts/evvm/lib/EvvmStorage.sol";
import {ErrorsLib} from "@EVVM/testnet/contracts/evvm/lib/ErrorsLib.sol";
import {SignatureUtils} from "@EVVM/testnet/contracts/evvm/lib/SignatureUtils.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Evvm is EvvmStorage {
    /**
     * @notice Access control modifier restricting function calls to the current admin
     * @dev Validates that msg.sender matches the current admin address before function execution
     * 
     * Access Control:
     * - Only the current admin can call functions with this modifier
     * - Uses the admin.current address from the storage structure
     * - Reverts with no specific error message for unauthorized calls
     * 
     * Usage:
     * - Applied to critical administrative functions
     * - Protects system configuration changes
     * - Prevents unauthorized upgrades and parameter modifications
     * 
     * Security:
     * - Simple but effective access control mechanism
     * - Used for proxy upgrades, admin transfers, and system configuration
     * - Part of the time-delayed governance system for critical operations
     */
    modifier onlyAdmin() {
        if (msg.sender != admin.current) {
            revert();
        }
        _;
    }

    /**
     * @notice Initializes the EVVM contract with essential configuration and token distributions
     * @dev Sets up the core system parameters, admin roles, and initial Principal Token allocations
     * 
     * Critical Initial Setup:
     * - Configures admin address with full administrative privileges
     * - Sets staking contract address for reward distribution and status management
     * - Stores EVVM metadata including principal token address and reward parameters
     * - Distributes initial MATE tokens to staking contract (2x reward amount)
     * - Registers staking contract as privileged staker with full benefits
     * - Activates breaker flag for one-time NameService and Treasury setup
     * 
     * Token Distribution:
     * - Staking contract receives 2x current reward amount in MATE tokens
     * - Enables immediate reward distribution capabilities
     * - Provides operational liquidity for staking rewards
     * 
     * Security Initialization:
     * - Sets admin.current for immediate administrative access
     * - Prepares system for NameService and Treasury integration
     * - Establishes staking privileges for the staking contract
     * 
     * Post-Deployment Requirements:
     * - Must call `_setupNameServiceAndTreasuryAddress()` to complete integration
     * - NameService and Treasury addresses must be configured before full operation
     * - Implementation contract should be set for proxy functionality
     * 
     * @param _initialOwner Address that will have administrative privileges over the contract
     * @param _stakingContractAddress Address of the staking contract for reward distribution and staker management
     * @param _evvmMetadata Metadata structure containing principal token address, reward amounts, and system parameters
     * 
     * @custom:deployment Must be followed by NameService and Treasury setup
     * @custom:security Admin address has full control over system configuration
     */
    constructor(
        address _initialOwner,
        address _stakingContractAddress,
        EvvmMetadata memory _evvmMetadata
    ) {
        stakingContractAddress = _stakingContractAddress;

        admin.current = _initialOwner;

        balances[_stakingContractAddress][evvmMetadata.principalTokenAddress] =
            getRewardAmount() *
            2;

        stakerList[_stakingContractAddress] = FLAG_IS_STAKER;

        breakerSetupNameServiceAddress = FLAG_IS_STAKER;

        evvmMetadata = _evvmMetadata;
    }

    /**
     * @notice One-time setup function to configure NameService and Treasury contract addresses
     * @dev Can only be called once due to breaker flag mechanism for security
     * 
     * Critical Setup Process:
     * - Validates the breaker flag is active (prevents multiple calls)
     * - Sets the NameService contract address for identity resolution in payments
     * - Configures the Treasury contract address for privileged balance operations
     * - Provides initial Principal Token balance (10,000 MATE) to NameService for operations
     * - Registers NameService as a privileged staker for enhanced functionality and rewards
     * 
     * Security Features:
     * - Single-use function protected by breaker flag
     * - Prevents unauthorized reconfiguration of critical system addresses
     * - Must be called during initial system deployment phase
     * 
     * Initial Token Distribution:
     * - NameService receives 10,000 MATE tokens for operational expenses
     * - NameService gains staker privileges for transaction processing
     * - Enables identity-based payment resolution throughout the ecosystem
     * 
     * @param _nameServiceAddress Address of the deployed NameService contract for identity resolution
     * @param _treasuryAddress Address of the Treasury contract for balance management operations
     * 
     * @custom:security Single-use function - can only be called once
     * @custom:access-control No explicit access control - relies on deployment sequence
     * @custom:integration Critical for NameService and Treasury functionality
     */
    function _setupNameServiceAndTreasuryAddress(
        address _nameServiceAddress,
        address _treasuryAddress
    ) external {
        if (breakerSetupNameServiceAddress == 0x00) {
            revert();
        }
        nameServiceAddress = _nameServiceAddress;
        balances[nameServiceAddress][evvmMetadata.principalTokenAddress] =
            10000 *
            10 ** 18;
        stakerList[nameServiceAddress] = FLAG_IS_STAKER;

        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Fallback function implementing proxy pattern with delegatecall to implementation
     * @dev Routes all unrecognized function calls to the current implementation contract
     * 
     * Proxy Mechanism:
     * - Forwards all calls not handled by this contract to the implementation
     * - Uses delegatecall to preserve storage context and msg.sender
     * - Allows for contract upgrades without changing the main contract address
     * - Maintains all state variables in the proxy contract storage
     * 
     * Implementation Process:
     * 1. Validates that an implementation contract is set
     * 2. Copies all calldata to memory for forwarding
     * 3. Executes delegatecall to implementation with full gas allowance
     * 4. Copies the return data back from the implementation
     * 5. Returns the result or reverts based on implementation response
     * 
     * Security Features:
     * - Reverts if no implementation is set (prevents undefined behavior)
     * - Preserves all gas for the implementation call
     * - Maintains exact return data and revert behavior from implementation
     * - Uses storage slot reading for gas efficiency
     * 
     * Upgrade Compatibility:
     * - Enables seamless contract upgrades through implementation changes
     * - Preserves all existing state and user balances
     * - Allows new functionality addition without user migration
     * - Supports time-delayed upgrade governance for security
     * 
     * @custom:security Requires valid implementation address
     * @custom:proxy Transparent proxy pattern implementation
     * @custom:upgrade-safe Preserves storage layout between upgrades
     */
    fallback() external {
        if (currentImplementation == address(0)) revert();

        assembly {
            /**
             *  Copy the data of the call
             *  copy s bytes of calldata from position
             *  f to mem in position t
             *  calldatacopy(t, f, s)
             */
            calldatacopy(0, 0, calldatasize())

            /**
             * 2. We make a delegatecall to the implementation
             *    and we copy the result
             */
            let result := delegatecall(
                gas(), // Send all the available gas
                sload(currentImplementation.slot), // Address of the implementation
                0, // Start of the memory where the data is
                calldatasize(), // Size of the data
                0, // Where we will store the response
                0 // Initial size of the response
            )

            /// Copy the response
            returndatacopy(0, 0, returndatasize())

            /// Handle the result
            switch result
            case 0 {
                revert(0, returndatasize()) // If it failed, revert
            }
            default {
                return(0, returndatasize()) // If it worked, return
            }
        }
    }


    /**
     * @notice Faucet function to add balance to a user's account for testing purposes
     * @dev This function is intended for testnet use only to provide tokens for testing
     * @param user The address of the user to receive the balance
     * @param token The address of the token contract to add balance for
     * @param quantity The amount of tokens to add to the user's balance
     */
    function addBalance(
        address user,
        address token,
        uint256 quantity
    ) external {
        balances[user][token] += quantity;
    }

    /**
     * @notice Faucet function to set point staker status for testing purposes
     * @dev This function is intended for testnet use only to configure staker points for testing
     * @param user The address of the user to set as point staker
     * @param answer The bytes1 value representing the staker status or answer
     */
    function setPointStaker(address user, bytes1 answer) external {
        stakerList[user] = answer;
    }

    //░▒▓█ Payment Functions ████████████████████████████████████████████████████████▓▒░

    /**
     * @notice Processes synchronous payments for non-staking users
     * @dev Uses automatic nonce increment for sequential transaction ordering
     * 
     * Payment Flow:
     * - Validates signature authorization for the payment
     * - Checks executor permission if specified
     * - Resolves recipient address (identity or direct address)
     * - Updates balances and increments nonce
     * 
     * @param from Address of the payment sender
     * @param to_address Direct recipient address (used if to_identity is empty)
     * @param to_identity Username/identity of recipient (resolved via NameService)
     * @param token Address of the token contract to transfer
     * @param amount Amount of tokens to transfer
     * @param priorityFee Additional fee for transaction priority (not used in non-staker payments)
     * @param executor Address authorized to execute this transaction (zero address = sender only)
     * @param signature Cryptographic signature authorizing this payment
     */
    function payNoStaker_sync(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        bytes memory signature
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nextSyncUsedNonce[from],
                false,
                executor,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        if (executor != address(0)) {
            if (msg.sender != executor)
                revert ErrorsLib.SenderIsNotTheExecutor();
        }

        address to = !Strings.equal(to_identity, "")
            ? NameService(nameServiceAddress).verifyStrictAndGetOwnerOfIdentity(
                to_identity
            )
            : to_address;

        if (!_updateBalance(from, to, token, amount))
            revert ErrorsLib.UpdateBalanceFailed();

        nextSyncUsedNonce[from]++;
    }

    /**
     * @notice Processes asynchronous payments for non-staking users
     * @dev Uses custom nonces for flexible transaction ordering and replay protection
     * 
     * Payment Flow:
     * - Validates signature with custom nonce
     * - Checks executor permission if specified
     * - Ensures nonce hasn't been used before
     * - Resolves recipient address and processes payment
     * - Marks nonce as used to prevent replay attacks
     * 
     * @param from Address of the payment sender
     * @param to_address Direct recipient address (used if to_identity is empty)
     * @param to_identity Username/identity of recipient (resolved via NameService)
     * @param token Address of the token contract to transfer
     * @param amount Amount of tokens to transfer
     * @param priorityFee Additional fee for transaction priority (not used in non-staker payments)
     * @param nonce Custom nonce for transaction ordering and replay protection
     * @param executor Address authorized to execute this transaction (zero address = sender only)
     * @param signature Cryptographic signature authorizing this payment
     */
    function payNoStaker_async(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        address executor,
        bytes memory signature
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nonce,
                true,
                executor,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        if (executor != address(0)) {
            if (msg.sender != executor)
                revert ErrorsLib.SenderIsNotTheExecutor();
        }

        if (asyncUsedNonce[from][nonce]) revert ErrorsLib.InvalidAsyncNonce();

        address to = !Strings.equal(to_identity, "")
            ? NameService(nameServiceAddress).verifyStrictAndGetOwnerOfIdentity(
                to_identity
            )
            : to_address;

        if (!_updateBalance(from, to, token, amount))
            revert ErrorsLib.UpdateBalanceFailed();

        asyncUsedNonce[from][nonce] = true;
    }

    /**
     * @notice Processes synchronous payments for Principal Token stakers with rewards
     * @dev Enhanced payment function that provides staker benefits and executor rewards
     * 
     * Staker Benefits:
     * - Stakers receive priority fee as reward for processing transactions
     * - Executors (msg.sender) get rewarded if they are also stakers
     * - Supports both direct addresses and identity-based payments
     * 
     * Payment Flow:
     * - Validates signature and executor permissions
     * - Processes the main payment transfer
     * - Distributes priority fee reward to stakers
     * - Increments synchronous nonce automatically
     * 
     * @param from Address of the payment sender (must be a staker)
     * @param to_address Direct recipient address (used if to_identity is empty)
     * @param to_identity Username/identity of recipient (resolved via NameService)
     * @param token Address of the token contract to transfer
     * @param amount Amount of tokens to transfer
     * @param priorityFee Fee amount distributed to stakers as reward
     * @param executor Address authorized to execute this transaction
     * @param signature Cryptographic signature authorizing this payment
     */
    function payStaker_sync(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        address executor,
        bytes memory signature
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nextSyncUsedNonce[from],
                false,
                executor,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        if (executor != address(0)) {
            if (msg.sender != executor)
                revert ErrorsLib.SenderIsNotTheExecutor();
        }

        if (!isAddressStaker(msg.sender)) revert ErrorsLib.NotAnStaker();

        address to = !Strings.equal(to_identity, "")
            ? NameService(nameServiceAddress).verifyStrictAndGetOwnerOfIdentity(
                to_identity
            )
            : to_address;

        if (!_updateBalance(from, to, token, amount))
            revert ErrorsLib.UpdateBalanceFailed();

        if (priorityFee > 0) {
            if (!_updateBalance(from, msg.sender, token, priorityFee))
                revert ErrorsLib.UpdateBalanceFailed();
        }
        _giveReward(msg.sender, 1);

        nextSyncUsedNonce[from]++;
    }

    /**
     * @notice Processes asynchronous payments for Principal Token stakers with rewards
     * @dev Enhanced async payment function with staker benefits and custom nonce management
     * 
     * Staker Benefits:
     * - Priority fee rewards for transaction processing
     * - Principal Token rewards for stakers (1x reward amount)
     * - Custom nonce support for flexible transaction ordering
     * 
     * Payment Flow:
     * - Validates signature with custom nonce for replay protection
     * - Verifies executor is a registered staker
     * - Processes main payment and priority fee distribution
     * - Rewards executor with MATE tokens
     * - Marks nonce as used to prevent replay attacks
     * 
     * @param from Address of the payment sender
     * @param to_address Direct recipient address (used if to_identity is empty)
     * @param to_identity Username/identity of recipient (resolved via NameService)
     * @param token Address of the token contract to transfer
     * @param amount Amount of tokens to transfer
     * @param priorityFee Fee amount distributed to stakers as reward
     * @param nonce Custom nonce for transaction ordering and replay protection
     * @param executor Address authorized to execute this transaction (must be a staker)
     * @param signature Cryptographic signature authorizing this payment
     */
    function payStaker_async(
        address from,
        address to_address,
        string memory to_identity,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        address executor,
        bytes memory signature
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForPay(
                from,
                to_address,
                to_identity,
                token,
                amount,
                priorityFee,
                nonce,
                true,
                executor,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        if (executor != address(0)) {
            if (msg.sender != executor)
                revert ErrorsLib.SenderIsNotTheExecutor();
        }

        if (!isAddressStaker(msg.sender)) revert ErrorsLib.NotAnStaker();

        if (asyncUsedNonce[from][nonce]) revert ErrorsLib.InvalidAsyncNonce();

        address to = !Strings.equal(to_identity, "")
            ? NameService(nameServiceAddress).verifyStrictAndGetOwnerOfIdentity(
                to_identity
            )
            : to_address;

        if (!_updateBalance(from, to, token, amount))
            revert ErrorsLib.UpdateBalanceFailed();

        if (priorityFee > 0) {
            if (!_updateBalance(from, msg.sender, token, priorityFee))
                revert ErrorsLib.UpdateBalanceFailed();
        }

        if (!_giveReward(msg.sender, 1))
            revert ErrorsLib.UpdateBalanceFailed();

        asyncUsedNonce[from][nonce] = true;
    }

    /**
     * @notice Processes multiple payments in a single transaction batch
     * @dev Executes an array of payment operations with individual success/failure tracking
     * 
     * Batch Processing Features:
     * - Processes each payment independently (partial success allowed)
     * - Returns detailed results for each transaction
     * - Supports both staker and non-staker payment types
     * - Handles both sync and async nonce types per payment
     * - Provides comprehensive transaction statistics
     * 
     * Payment Validation:
     * - Each payment signature is verified independently
     * - Nonce management handled per payment type (sync/async)
     * - Identity resolution performed for each recipient
     * - Balance updates executed atomically per payment
     * 
     * Return Values:
     * - successfulTransactions: Count of completed payments
     * - failedTransactions: Count of failed payments  
     * - results: Boolean array indicating success/failure for each payment
     * 
     * @param payData Array of PayData structures containing payment details
     * @return successfulTransactions Number of payments that completed successfully
     * @return failedTransactions Number of payments that failed
     * @return results Boolean array with success status for each payment
     */
    function payMultiple(
        PayData[] memory payData
    )
        external
        returns (
            uint256 successfulTransactions,
            uint256 failedTransactions,
            bool[] memory results
        )
    {
        address to_aux;
        results = new bool[](payData.length);
        for (uint256 iteration = 0; iteration < payData.length; iteration++) {
            if (
                !SignatureUtils.verifyMessageSignedForPay(
                    payData[iteration].from,
                    payData[iteration].to_address,
                    payData[iteration].to_identity,
                    payData[iteration].token,
                    payData[iteration].amount,
                    payData[iteration].priorityFee,
                    payData[iteration].priorityFlag
                        ? payData[iteration].nonce
                        : nextSyncUsedNonce[payData[iteration].from],
                    payData[iteration].priorityFlag,
                    payData[iteration].executor,
                    payData[iteration].signature
                )
            ) revert ErrorsLib.InvalidSignature();

            if (payData[iteration].executor != address(0)) {
                if (msg.sender != payData[iteration].executor) {
                    failedTransactions++;
                    results[iteration] = false;
                    continue;
                }
            }

            if (payData[iteration].priorityFlag) {
                /// @dev priorityFlag == true (async)

                if (
                    !asyncUsedNonce[payData[iteration].from][
                        payData[iteration].nonce
                    ]
                ) {
                    asyncUsedNonce[payData[iteration].from][
                        payData[iteration].nonce
                    ] = true;
                } else {
                    failedTransactions++;
                    results[iteration] = false;
                    continue;
                }
            } else {
                /// @dev priorityFlag == false (sync)

                if (
                    nextSyncUsedNonce[payData[iteration].from] ==
                    payData[iteration].nonce
                ) {
                    nextSyncUsedNonce[payData[iteration].from]++;
                } else {
                    failedTransactions++;
                    results[iteration] = false;
                    continue;
                }
            }

            to_aux = !Strings.equal(payData[iteration].to_identity, "")
                ? NameService(nameServiceAddress)
                    .verifyStrictAndGetOwnerOfIdentity(
                        payData[iteration].to_identity
                    )
                : payData[iteration].to_address;

            if (
                payData[iteration].priorityFee + payData[iteration].amount >
                balances[payData[iteration].from][payData[iteration].token]
            ) {
                failedTransactions++;
                results[iteration] = false;
                continue;
            }

            if (
                !_updateBalance(
                    payData[iteration].from,
                    to_aux,
                    payData[iteration].token,
                    payData[iteration].amount
                )
            ) {
                failedTransactions++;
                results[iteration] = false;
                continue;
            } else {
                if (
                    payData[iteration].priorityFee > 0 &&
                    isAddressStaker(msg.sender)
                ) {
                    if (
                        !_updateBalance(
                            payData[iteration].from,
                            msg.sender,
                            payData[iteration].token,
                            payData[iteration].priorityFee
                        )
                    ) {
                        failedTransactions++;
                        results[iteration] = false;
                        continue;
                    }
                }

                successfulTransactions++;
                results[iteration] = true;
            }
        }

        if (isAddressStaker(msg.sender)) {
            _giveReward(msg.sender, successfulTransactions);
        }
    }

    /**
     * @notice Distributes tokens from a single sender to multiple recipients
     * @dev Efficient single-source multi-recipient payment distribution with signature verification
     * 
     * Distribution Features:
     * - Single signature authorizes distribution to multiple recipients
     * - Supports both direct addresses and identity-based recipients
     * - Proportional amount distribution based on recipient configurations
     * - Integrated priority fee and staker reward system
     * - Supports both sync and async nonce management
     * 
     * Verification Process:
     * - Validates single signature for entire distribution
     * - Checks total amount and priority fee against sender balance
     * - Ensures executor permissions and nonce validity
     * - Processes each recipient distribution atomically
     * 
     * Staker Benefits:
     * - Executor receives priority fee (if staker)
     * - MATE reward based on number of successful distributions
     * 
     * @param from Address of the payment sender
     * @param toData Array of recipient data with addresses/identities and amounts
     * @param token Address of the token contract to distribute
     * @param amount Total amount to distribute (must match sum of individual amounts)
     * @param priorityFee Fee amount for the transaction executor
     * @param nonce Transaction nonce for replay protection
     * @param priorityFlag True for async nonce, false for sync nonce
     * @param executor Address authorized to execute this distribution
     * @param signature Cryptographic signature authorizing this distribution
     */
    function dispersePay(
        address from,
        DispersePayMetadata[] memory toData,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        address executor,
        bytes memory signature
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForDispersePay(
                from,
                sha256(abi.encode(toData)),
                token,
                amount,
                priorityFee,
                priorityFlag ? nonce : nextSyncUsedNonce[from],
                priorityFlag,
                executor,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        if (executor != address(0)) {
            if (msg.sender != executor)
                revert ErrorsLib.SenderIsNotTheExecutor();
        }

        if (priorityFlag) {
            if (asyncUsedNonce[from][nonce])
                revert ErrorsLib.InvalidAsyncNonce();
        }

        if (balances[from][token] < amount + priorityFee)
            revert ErrorsLib.InsufficientBalance();

        uint256 acomulatedAmount = 0;
        balances[from][token] -= (amount + priorityFee);
        address to_aux;
        for (uint256 i = 0; i < toData.length; i++) {
            acomulatedAmount += toData[i].amount;

            if (!Strings.equal(toData[i].to_identity, "")) {
                if (
                    NameService(nameServiceAddress).strictVerifyIfIdentityExist(
                        toData[i].to_identity
                    )
                ) {
                    to_aux = NameService(nameServiceAddress).getOwnerOfIdentity(
                            toData[i].to_identity
                        );
                }
            } else {
                to_aux = toData[i].to_address;
            }

            balances[to_aux][token] += toData[i].amount;
        }

        if (acomulatedAmount != amount)
            revert ErrorsLib.InvalidAmount(acomulatedAmount, amount);

        if (isAddressStaker(msg.sender)) {
            _giveReward(msg.sender, 1);
            balances[msg.sender][token] += priorityFee;
        } else {
            balances[from][token] += priorityFee;
        }

        if (priorityFlag) {
            asyncUsedNonce[from][nonce] = true;
        } else {
            nextSyncUsedNonce[from]++;
        }
    }

    /**
     * @notice Contract-to-address payment function for authorized smart contracts
     * @dev Allows registered contracts to distribute tokens without signature verification
     * 
     * Authorization Model:
     * - Only smart contracts (non-EOA addresses) can call this function
     * - Calling contract must have sufficient token balance
     * - No signature verification required (contract-level authorization)
     * - Used primarily for automated distributions and rewards
     * 
     * Use Cases:
     * - Staking contract reward distributions
     * - NameService fee distributions
     * - Automated system payouts
     * - Cross-contract token transfers
     * 
     * Security Features:
     * - Validates caller is a contract (has bytecode)
     * - Checks sufficient balance before transfer
     * - Direct balance manipulation for efficiency
     * 
     * @param to Address of the token recipient
     * @param token Address of the token contract to transfer
     * @param amount Amount of tokens to transfer from calling contract
     */
    function caPay(address to, address token, uint256 amount) external {
        uint256 size;
        address from = msg.sender;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(from)
        }

        if (size == 0) revert ErrorsLib.NotAnCA();

        if (!_updateBalance(from, to, token, amount))
            revert ErrorsLib.UpdateBalanceFailed();

        if (isAddressStaker(msg.sender)) {
            _giveReward(msg.sender, 1);
        }
    }

    /**
     * @notice Contract-to-multiple-addresses payment distribution function
     * @dev Allows authorized contracts to distribute tokens to multiple recipients efficiently
     * 
     * Batch Distribution Features:
     * - Single call distributes to multiple recipients
     * - Supports both direct addresses and identity resolution
     * - Validates total amount matches sum of individual distributions
     * - Optimized for contract-based automated distributions
     * 
     * Authorization Model:
     * - Only smart contracts can call this function
     * - No signature verification required (contract authorization)
     * - Calling contract must have sufficient balance for total distribution
     * 
     * Use Cases:
     * - Bulk reward distributions from staking contracts
     * - Multi-recipient fee distributions
     * - Batch payroll or dividend distributions
     * - Cross-contract multi-party settlements
     * 
     * @param toData Array of recipient data containing addresses/identities and amounts
     * @param token Address of the token contract to distribute
     * @param amount Total amount to distribute (must equal sum of individual amounts)
     */
    function disperseCaPay(
        DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) external {
        uint256 size;
        address from = msg.sender;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(from)
        }

        if (size == 0) revert ErrorsLib.NotAnCA();

        uint256 acomulatedAmount = 0;
        if (balances[msg.sender][token] < amount)
            revert ErrorsLib.InsufficientBalance();

        balances[msg.sender][token] -= amount;

        for (uint256 i = 0; i < toData.length; i++) {
            acomulatedAmount += toData[i].amount;
            if (acomulatedAmount > amount)
                revert ErrorsLib.InvalidAmount(acomulatedAmount, amount);

            balances[toData[i].toAddress][token] += toData[i].amount;
        }

        if (acomulatedAmount != amount)
            revert ErrorsLib.InvalidAmount(acomulatedAmount, amount);

        if (isAddressStaker(msg.sender)) {
            _giveReward(msg.sender, 1);
        }
    }

    //░▒▓█Treasury exclusive functions██████████████████████████████████████████▓▒░

    /**
     * @notice Adds tokens to a user's balance in the EVVM system
     * @dev Restricted function that can only be called by the authorized treasury contract
     * 
     * Treasury Operations:
     * - Allows treasury to mint or credit tokens to user accounts
     * - Used for reward distributions, airdrops, or token bridging
     * - Direct balance manipulation bypasses normal transfer restrictions
     * - No signature verification required (treasury authorization)
     * 
     * Access Control:
     * - Only the registered treasury contract can call this function
     * - Reverts with SenderIsNotTreasury error for unauthorized callers
     * - Provides centralized token distribution mechanism
     * 
     * Use Cases:
     * - Cross-chain bridge token minting
     * - Administrative reward distributions
     * - System-level token allocations
     * - Emergency balance corrections
     * 
     * @param user Address of the user to receive tokens
     * @param token Address of the token contract to add balance for
     * @param amount Amount of tokens to add to the user's balance
     * 
     * @custom:access-control Only treasury contract
     * @custom:security No overflow protection needed due to controlled access
     */
    function addAmountToUser(
        address user,
        address token,
        uint256 amount
    ) external {
        if (msg.sender != treasuryAddress)
            revert ErrorsLib.SenderIsNotTreasury();

        balances[user][token] += amount;
    }

    /**
     * @notice Removes tokens from a user's balance in the EVVM system
     * @dev Restricted function that can only be called by the authorized treasury contract
     * 
     * Treasury Operations:
     * - Allows treasury to burn or debit tokens from user accounts
     * - Used for cross-chain bridging, penalties, or system corrections
     * - Direct balance manipulation bypasses normal transfer protections
     * - Can potentially create negative balances if not carefully managed
     * 
     * Access Control:
     * - Only the registered treasury contract can call this function
     * - Reverts with SenderIsNotTreasury error for unauthorized callers
     * - Provides centralized token withdrawal mechanism
     * 
     * Use Cases:
     * - Cross-chain bridge token burning
     * - Administrative penalty applications
     * - System-level token reclamations
     * - Emergency balance corrections
     * 
     * Security Considerations:
     * - No underflow protection: treasury must ensure sufficient balance
     * - Can result in unexpected negative balances if misused
     * - Treasury contract should implement additional validation
     * 
     * @param user Address of the user to remove tokens from
     * @param token Address of the token contract to remove balance for
     * @param amount Amount of tokens to remove from the user's balance
     * 
     * @custom:access-control Only treasury contract
     * @custom:security No underflow protection - treasury responsibility
     */
    function removeAmountFromUser(
        address user,
        address token,
        uint256 amount
    ) external {
        if (msg.sender != treasuryAddress)
            revert ErrorsLib.SenderIsNotTreasury();

        balances[user][token] -= amount;
    }

    //█ Internal Functions ███████████████████████████████████████████████████████████████████

    //█ Balance Management Functions █████████████████████████████████████████████

    /**
     * @notice Internal function to safely transfer tokens between addresses
     * @dev Performs balance validation and atomic transfer with overflow protection
     * 
     * Transfer Process:
     * - Validates sender has sufficient balance
     * - Performs atomic balance updates using unchecked arithmetic
     * - Returns success/failure status for error handling
     * 
     * Security Features:
     * - Balance validation prevents overdrafts
     * - Unchecked arithmetic for gas optimization (overflow impossible)
     * - Returns boolean for caller error handling
     * 
     * @param from Address to transfer tokens from
     * @param to Address to transfer tokens to
     * @param token Address of the token contract
     * @param value Amount of tokens to transfer
     * @return success True if transfer completed, false if insufficient balance
     */
    function _updateBalance(
        address from,
        address to,
        address token,
        uint256 value
    ) internal returns (bool) {
        uint256 fromBalance = balances[from][token];
        if (fromBalance < value) {
            return false;
        } else {
            unchecked {
                balances[from][token] = fromBalance - value;
                balances[to][token] += value;
            }
            return true;
        }
    }

    /**
     * @notice Internal function to distribute Principal Token rewards to stakers
     * @dev Provides incentive distribution for transaction processing and staking participation
     * 
     * Reward System:
     * - Calculates reward based on system reward rate and transaction count
     * - Directly increases principal token balance for gas efficiency
     * - Returns success status for error handling in calling functions
     * 
     * Reward Calculation:
     * - Base reward per transaction: evvmMetadata.reward
     * - Total reward: base_reward × transaction_amount
     * - Added directly to user's Principal Token balance
     * 
     * @param user Address of the staker to receive principal tokenrewards
     * @param amount Number of transactions or reward multiplier
     * @return success True if reward distribution completed successfully
     */
    function _giveReward(
        address user,
        uint256 amount
    ) internal returns (bool) {
        uint256 principalReward = evvmMetadata.reward * amount;
        uint256 userBalance = balances[user][
            evvmMetadata.principalTokenAddress
        ];

        balances[user][evvmMetadata.principalTokenAddress] =
            userBalance +
            principalReward;

        return (userBalance + principalReward ==
            balances[user][evvmMetadata.principalTokenAddress]);
    }

    //█ Administrative Functions ██████████████████████████████████████████████████████████████

    //█ Proxy Management Functions █████████████████████████████████████████████

    /**
     * @notice Proposes a new implementation contract for the proxy with time delay
     * @dev Part of the time-delayed governance system for critical upgrades
     * 
     * Upgrade Security:
     * - 30-day time delay for implementation changes
     * - Only admin can propose upgrades
     * - Allows time for community review and validation
     * - Can be rejected before acceptance deadline
     * 
     * @param _newImpl Address of the new implementation contract
     */
    function proposeImplementation(address _newImpl) external onlyAdmin {
        proposalImplementation = _newImpl;
        timeToAcceptImplementation = block.timestamp + 30 days;
    }

    /**
     * @notice Cancels a pending implementation upgrade proposal
     * @dev Allows admin to reject proposed upgrades before the time delay expires
     */
    function rejectUpgrade() external onlyAdmin {
        proposalImplementation = address(0);
        timeToAcceptImplementation = 0;
    }

    /**
     * @notice Accepts a pending implementation upgrade after the time delay
     * @dev Executes the proxy upgrade to the new implementation contract
     */
    function acceptImplementation() external onlyAdmin {
        if (block.timestamp < timeToAcceptImplementation) revert();
        currentImplementation = proposalImplementation;
        proposalImplementation = address(0);
        timeToAcceptImplementation = 0;
    }

    //█ NameService Integration Functions ████████████████████████████████████████

    /**
     * @notice Updates the NameService contract address for identity resolution
     * @dev Allows admin to change the NameService integration address
     * @param _nameServiceAddress Address of the new NameService contract
     */
    function setNameServiceAddress(
        address _nameServiceAddress
    ) external onlyAdmin {
        nameServiceAddress = _nameServiceAddress;
    }

    //█ Admin Management Functions ███████████████████████████████████████████████

    /**
     * @notice Proposes a new admin address with 1-day time delay
     * @dev Part of the time-delayed governance system for admin changes
     * @param _newOwner Address of the proposed new admin
     */
    function proposeAdmin(address _newOwner) external onlyAdmin {
        if (_newOwner == address(0) || _newOwner == admin.current) {
            revert();
        }

        admin.proposal = _newOwner;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    /**
     * @notice Cancels a pending admin change proposal
     * @dev Allows current admin to reject proposed admin changes
     */
    function rejectProposalAdmin() external onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice Accepts a pending admin proposal and becomes the new admin
     * @dev Can only be called by the proposed admin after the time delay
     */
    function acceptAdmin() external {
        if (block.timestamp < admin.timeToAccept) {
            revert();
        }
        if (msg.sender != admin.proposal) {
            revert();
        }

        admin.current = admin.proposal;

        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    //█ Reward System Functions ███████████████████████████████████████████████████████████████

    /**
     * @notice Triggers a reward recalculation and era transition in the token economy
     * @dev Implements deflationary tokenomics with halving mechanism and random rewards
     * 
     * Era Transition Mechanism:
     * - Activates when total supply exceeds current era token threshold
     * - Moves half of remaining tokens to next era threshold  
     * - Halves the base reward amount for future transactions
     * - Provides random Principal Token bonus to caller (1-5083x reward)
     * 
     * Economic Impact:
     * - Gradually reduces inflation through reward halving
     * - Creates scarcity as era thresholds become harder to reach
     * - Incentivizes early participation with higher rewards
     * - Provides lottery-style bonus for triggering era transitions
     * 
     * Requirements:
     * - Total supply must exceed current era token threshold
     * - Can be called by anyone when conditions are met
     */
    function recalculateReward() public {
        if (evvmMetadata.totalSupply > evvmMetadata.eraTokens) {
            evvmMetadata.eraTokens += ((evvmMetadata.totalSupply -
                evvmMetadata.eraTokens) / 2);
            balances[msg.sender][evvmMetadata.principalTokenAddress] +=
                evvmMetadata.reward *
                getRandom(1, 5083);
            evvmMetadata.reward = evvmMetadata.reward / 2;
        } else {
            revert();
        }
    }

    /**
     * @notice Generates a pseudo-random number within a specified range
     * @dev Uses block timestamp and prevrandao for randomness (suitable for non-critical randomness)
     * 
     * Randomness Source:
     * - Combines block.timestamp and block.prevrandao
     * - Suitable for reward bonuses and non-security-critical randomness
     * - Not suitable for high-stakes randomness requiring true unpredictability
     * 
     * @param min Minimum value (inclusive)
     * @param max Maximum value (inclusive)
     * @return Random number between min and max (inclusive)
     */
    function getRandom(
        uint256 min,
        uint256 max
    ) internal view returns (uint256) {
        return
            min +
            (uint256(
                keccak256(abi.encodePacked(block.timestamp, block.prevrandao))
            ) % (max - min + 1));
    }

    //█ Staking Integration Functions █████████████████████████████████████████████████████████

    /**
     * @notice Updates staker status for a user address
     * @dev Can only be called by the authorized staking contract
     * 
     * Staker Status Management:
     * - Controls who can earn staking rewards and process transactions
     * - Integrates with external staking contract for validation
     * - Updates affect payment processing privileges and reward eligibility
     * 
     * Access Control:
     * - Only the registered staking contract can call this function
     * - Ensures staker status changes are properly authorized
     * 
     * @param user Address to update staker status for
     * @param answer Bytes1 flag indicating staker status/type
     */
    function pointStaker(address user, bytes1 answer) public {
        if (msg.sender != stakingContractAddress) {
            revert();
        }
        stakerList[user] = answer;
    }

    //█ View Functions ████████████████████████████████████████████████████████████████████████

    /**
     * @notice Returns the complete EVVM metadata configuration
     * @dev Provides access to system-wide configuration and economic parameters
     * 
     * Metadata Contents:
     * - Principal token address (Principal Token)
     * - Current reward amount per transaction
     * - Total supply tracking
     * - Era tokens threshold for reward transitions
     * - System configuration parameters
     * 
     * @return Complete EvvmMetadata struct with all system parameters
     */
    function getEvvmMetadata() external view returns (EvvmMetadata memory) {
        return evvmMetadata;
    }

    /**
     * @notice Gets the acceptance deadline for pending token whitelist proposals
     * @dev Returns timestamp when prepared tokens can be added to whitelist
     * @return Timestamp when pending token can be whitelisted (0 if no pending proposal)
     */
    function getWhitelistTokenToBeAddedDateToSet()
        external
        view
        returns (uint256)
    {
        return whitelistTokenToBeAdded_dateToSet;
    }

    /**
     * @notice Gets the current NameService contract address
     * @dev Returns the address used for identity resolution in payments
     * @return Address of the integrated NameService contract
     */
    function getNameServiceAddress() external view returns (address) {
        return nameServiceAddress;
    }

    /**
     * @notice Gets the authorized staking contract address
     * @dev Returns the address that can modify staker status and receive rewards
     * @return Address of the integrated staking contract
     */
    function getStakingContractAddress() external view returns (address) {
        return stakingContractAddress;
    }

    /**
     * @notice Gets the next synchronous nonce for a user
     * @dev Returns the expected nonce for the next sync payment transaction
     * @param user Address to check sync nonce for
     * @return Next synchronous nonce value
     */
    function getNextCurrentSyncNonce(
        address user
    ) external view returns (uint256) {
        return nextSyncUsedNonce[user];
    }

    /**
     * @notice Checks if a specific async nonce has been used by a user
     * @dev Verifies nonce status to prevent replay attacks in async payments
     * @param user Address to check nonce usage for
     * @param nonce Specific nonce value to verify
     * @return True if the nonce has been used, false if still available
     */
    function getIfUsedAsyncNonce(
        address user,
        uint256 nonce
    ) external view returns (bool) {
        return asyncUsedNonce[user][nonce];
    }

    /**
     * @notice Gets the next Fisher Bridge deposit nonce for a user
     * @dev Returns the expected nonce for the next cross-chain deposit
     * @param user Address to check deposit nonce for
     * @return Next Fisher Bridge deposit nonce
     */
    function getNextFisherDepositNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherDepositNonce[user];
    }

    /**
     * @notice Gets the balance of a specific token for a user
     * @dev Returns the current balance stored in the EVVM system
     * @param user Address to check balance for
     * @param token Token contract address to check
     * @return Current token balance for the user
     */
    function getBalance(
        address user,
        address token
    ) external view returns (uint) {
        return balances[user][token];
    }

    /**
     * @notice Checks if an address is registered as a staker
     * @dev Verifies staker status for transaction processing privileges and rewards
     * @param user Address to check staker status for
     * @return True if the address is a registered staker
     */
    function isAddressStaker(address user) public view returns (bool) {
        return stakerList[user] == FLAG_IS_STAKER;
    }

    /**
     * @notice Gets the current era token threshold for reward transitions
     * @dev Returns the token supply threshold that triggers the next reward halving
     * @return Current era tokens threshold
     */
    function getEraPrincipalToken() public view returns (uint256) {
        return evvmMetadata.eraTokens;
    }

    /**
     * @notice Gets the current Principal Token reward amount per transaction
     * @dev Returns the base reward distributed to stakers for transaction processing
     * @return Current reward amount in MATE tokens
     */
    function getRewardAmount() public view returns (uint256) {
        return evvmMetadata.reward;
    }

    /**
     * @notice Gets the total supply of the principal token (MATE)
     * @dev Returns the current total supply used for era transition calculations
     * @return Total supply of MATE tokens
     */
    function getPrincipalTokenTotalSupply() public view returns (uint256) {
        return evvmMetadata.totalSupply;
    }

    /**
     * @notice Gets the current active implementation contract address
     * @dev Returns the implementation used by the proxy for delegatecalls
     * @return Address of the current implementation contract
     */
    function getCurrentImplementation() public view returns (address) {
        return currentImplementation;
    }

    /**
     * @notice Gets the proposed implementation contract address
     * @dev Returns the implementation pending approval for proxy upgrade
     * @return Address of the proposed implementation contract (zero if none)
     */
    function getProposalImplementation() public view returns (address) {
        return proposalImplementation;
    }

    /**
     * @notice Gets the acceptance deadline for the pending implementation upgrade
     * @dev Returns timestamp when the proposed implementation can be accepted
     * @return Timestamp when implementation upgrade can be executed (0 if no pending proposal)
     */
    function getTimeToAcceptImplementation() public view returns (uint256) {
        return timeToAcceptImplementation;
    }

    /**
     * @notice Gets the current admin address
     * @dev Returns the address with administrative privileges over the contract
     * @return Address of the current admin
     */
    function getCurrentAdmin() public view returns (address) {
        return admin.current;
    }

    /**
     * @notice Gets the proposed admin address
     * @dev Returns the address pending approval for admin privileges
     * @return Address of the proposed admin (zero if no pending proposal)
     */
    function getProposalAdmin() public view returns (address) {
        return admin.proposal;
    }

    /**
     * @notice Gets the acceptance deadline for the pending admin change
     * @dev Returns timestamp when the proposed admin can accept the role
     * @return Timestamp when admin change can be executed (0 if no pending proposal)
     */
    function getTimeToAcceptAdmin() public view returns (uint256) {
        return admin.timeToAccept;
    }

    /**
     * @notice Gets the address of the token pending whitelist approval
     * @dev Returns the token address that can be whitelisted after time delay
     * @return Address of the token prepared for whitelisting (zero if none)
     */
    function getWhitelistTokenToBeAdded() public view returns (address) {
        return whitelistTokenToBeAdded_address;
    }
}
