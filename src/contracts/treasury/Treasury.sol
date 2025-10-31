// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
░██████████                                                     
    ░██                                                         
    ░█░██░███░███████░██████ ░███████░██    ░█░██░███░██    ░██ 
    ░█░███  ░██    ░██    ░█░██      ░██    ░█░███   ░██    ░██ 
    ░█░██   ░████████░███████░███████░██    ░█░██    ░██    ░██ 
    ░█░██   ░██     ░██   ░██      ░█░██   ░██░██    ░██   ░███ 
    ░█░██    ░███████░█████░█░███████ ░█████░█░██     ░█████░██ 
                                                            ░██ 
                                                      ░███████  
                                                                
████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
            
 * @title Treasury Contract
 * @author Mate labs
 * @notice Treasury for managing deposits and withdrawals in the EVVM ecosystem
 * @dev Secure vault for ETH and ERC20 tokens with EVVM integration and input validation
 */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";
import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {ErrorsLib} from "@evvm/testnet-contracts/contracts/treasury/lib/ErrorsLib.sol";

contract Treasury {
    /// @notice Address of the EVVM core contract
    address public evvmAddress;

    /**
     * @notice Initialize Treasury with EVVM contract address
     * @param _evvmAddress Address of the EVVM core contract
     */
    constructor(address _evvmAddress) {
        evvmAddress = _evvmAddress;
    }

    /**
     * @notice Deposit ETH or ERC20 tokens
     * @param token ERC20 token address (ignored for ETH deposits)
     * @param amount Token amount (ignored for ETH deposits)
     */
    function deposit(address token, uint256 amount) external payable {
        if (address(0) == token) {
            /// user is sending host native coin
            if (msg.value == 0)
                revert ErrorsLib.DepositAmountMustBeGreaterThanZero();
            if (amount != msg.value) revert ErrorsLib.InvalidDepositAmount();

            Evvm(evvmAddress).addAmountToUser(
                msg.sender,
                address(0),
                msg.value
            );
        } else {
            /// user is sending ERC20 tokens

            if (msg.value != 0) revert ErrorsLib.InvalidDepositAmount();
            if (amount == 0)
                revert ErrorsLib.DepositAmountMustBeGreaterThanZero();

            IERC20(token).transferFrom(msg.sender, address(this), amount);
            Evvm(evvmAddress).addAmountToUser(msg.sender, token, amount);
        }
    }

    /**
     * @notice Withdraw ETH or ERC20 tokens
     * @param token Token address (address(0) for ETH)
     * @param amount Amount to withdraw
     */
    function withdraw(address token, uint256 amount) external {
        if (token == Evvm(evvmAddress).getEvvmMetadata().principalTokenAddress)
            revert ErrorsLib.PrincipalTokenIsNotWithdrawable();

        if (Evvm(evvmAddress).getBalance(msg.sender, token) < amount)
            revert ErrorsLib.InsufficientBalance();

        if (token == address(0)) {
            /// user is trying to withdraw native coin

            Evvm(evvmAddress).removeAmountFromUser(
                msg.sender,
                address(0),
                amount
            );
            SafeTransferLib.safeTransferETH(msg.sender, amount);
        } else {
            /// user is trying to withdraw ERC20 tokens

            Evvm(evvmAddress).removeAmountFromUser(msg.sender, token, amount);
            IERC20(token).transfer(msg.sender, amount);
        }
    }
}
