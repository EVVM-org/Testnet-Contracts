// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {IStaking} from "@evvm/testnet-contracts/interfaces/IStaking.sol";
import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";

abstract contract StakingServiceUtils {
    IStaking internal staking;

    constructor(address stakingAddress) {
        staking = IStaking(stakingAddress);
    }

    function _makeStakeService(uint256 amountToStake) internal {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            IEvvm(staking.getEvvmAddress()).getPrincipalTokenAddress(),
            staking.priceOfStaking() * amountToStake
        );
        staking.confirmServiceStaking();
    }

    function _makeUnstakeService(uint256 amountToUnstake) internal {
        staking.serviceUnstaking(amountToUnstake);
    }

    function _changeStakingAddress(address newStakingAddress) internal virtual {
        staking = IStaking(newStakingAddress);
    }
}
