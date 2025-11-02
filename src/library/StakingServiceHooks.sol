// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

/**
 * @title StakingServiceHooks
 * @author Mate labs
 * @notice Abstract contract providing simplified staking functionality for service contracts
 * @dev This contract provides pre-built hooks for service contracts to easily interact with the EVVM staking system.
 *      It handles the complex 3-step staking process atomically to prevent token loss.
 * 
 * Key Features:
 * - Atomic service staking: Combines prepareServiceStaking, caPay, and confirmServiceStaking in one call
 * - Simplified unstaking for services
 * - Automatic address management for Staking and EVVM contracts
 * - Safe state management to prevent token loss
 * 
 * Usage:
 * - Inherit from this contract in your service contract
 * - Call makeStakeService(amount) to stake tokens safely
 * - Call makeUnstakeService(amount) to unstake tokens
 * 
 * IMPORTANT: The service contract must have sufficient Principal Token balance before calling makeStakeService
 */

import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";

abstract contract StakingServiceHooks {
    /// @dev Address of the Staking contract that handles staking operations
    address stakingHookAddress;
    /// @dev Address of the EVVM core contract that handles token operations
    address evvmHookAddress;
    
    /**
     * @notice Initializes the service hooks with the staking contract address
     * @dev Automatically retrieves and stores the EVVM contract address from the staking contract
     * @param _stakingAddress Address of the deployed Staking contract
     */
    constructor(address _stakingAddress) {
        stakingHookAddress = _stakingAddress;
        evvmHookAddress = Staking(stakingHookAddress).getEvvmAddress();
    }
    
    /**
     * @notice Performs atomic staking operation for the service contract
     * @dev Executes the complete 3-step staking process in a single transaction to prevent token loss:
     *      1. Prepares service staking (records pre-staking state)
     *      2. Transfers Principal Tokens to staking contract via caPay
     *      3. Confirms staking completion
     * 
     * @param amountToStake Number of staking tokens to stake (not Principal Tokens)
     * 
     * Requirements:
     * - Service must have sufficient Principal Token balance (amountToStake * PRICE_OF_STAKING)
     * - Service must not be in cooldown period from previous unstaking
     * - All operations must succeed in the same transaction
     * 
     * @dev CRITICAL: This function ensures atomicity - if any step fails, the entire transaction reverts
     *      preventing the loss of Principal Tokens that could occur with manual step-by-step execution
     */
    function _makeStakeService(uint256 amountToStake) internal {
        Staking(stakingHookAddress).prepareServiceStaking(amountToStake);
        Evvm(evvmHookAddress).caPay(
            address(stakingHookAddress),
            0x0000000000000000000000000000000000000001,
            Staking(stakingHookAddress).priceOfStaking() * amountToStake
        );
        Staking(stakingHookAddress).confirmServiceStaking();
    }

    /**
     * @notice Performs unstaking operation for the service contract
     * @dev Allows the service to withdraw staked tokens and receive Principal Tokens back
     * 
     * @param amountToUnstake Number of staking tokens to unstake
     * 
     * The service will receive: amountToUnstake * PRICE_OF_STAKING Principal Tokens
     * 
     * Requirements:
     * - Service must have at least amountToUnstake staking tokens staked
     * - If unstaking all tokens, must wait 21 days since last zero balance
     * - Cannot unstake more than currently staked amount
     * 
     * @dev Unstaking is subject to the same time locks as regular user unstaking
     */
    function _makeUnstakeService(uint256 amountToUnstake) internal {
        Staking(stakingHookAddress).serviceUnstaking(amountToUnstake);
    }

    /**
     * @notice Internal function to update the staking contract address
     * @dev Updates both staking and EVVM addresses. Should be used when staking contract is upgraded
     * @param newStakingAddress Address of the new Staking contract
     * 
     * @dev This function should be called by inheriting contracts when they need to migrate
     *      to a new version of the staking contract. It automatically updates the EVVM address too.
     */
    function _changeStakingHookAddress(address newStakingAddress) internal {
        stakingHookAddress = newStakingAddress;
        evvmHookAddress = Staking(stakingHookAddress).getEvvmAddress();
    }

    /**
     * @notice Internal function to manually update the EVVM contract address
     * @dev Updates only the EVVM address. Use when EVVM contract is upgraded independently
     * @param newEvvmAddress Address of the new EVVM contract
     * 
     * @dev This function should be used sparingly, typically only when the EVVM contract
     *      is upgraded but the staking contract remains the same. In most cases, prefer
     *      using _changeStakingHookAddress which updates both addresses automatically.
     */
    function _changeEvvmHookAddress(address newEvvmAddress) internal {
        evvmHookAddress = newEvvmAddress;
    }
}
