// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense
pragma solidity ^0.8.0;

import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {IStaking} from "@evvm/testnet-contracts/interfaces/IStaking.sol";

abstract contract StakingServiceUtils {
    address stakingHookAddress;
    address evvmHookAddress;
    constructor(address _stakingAddress) {
        stakingHookAddress = _stakingAddress;
        evvmHookAddress = IStaking(stakingHookAddress).getEvvmAddress();
    }
    function _makeStakeService(uint256 amountToStake) internal {
        IStaking(stakingHookAddress).prepareServiceStaking(amountToStake);
        IEvvm(evvmHookAddress).caPay(
            address(stakingHookAddress),
            0x0000000000000000000000000000000000000001,
            IStaking(stakingHookAddress).priceOfStaking() * amountToStake
        );
        IStaking(stakingHookAddress).confirmServiceStaking();
    }

    function _makeUnstakeService(uint256 amountToUnstake) internal {
        IStaking(stakingHookAddress).serviceUnstaking(amountToUnstake);
    }

    function _changeStakingAddress(address newStakingAddress) internal {
        stakingHookAddress = newStakingAddress;
        evvmHookAddress = IStaking(stakingHookAddress).getEvvmAddress();
    }

    function _changeEvvmHookAddress(address newEvvmAddress) internal {
        evvmHookAddress = newEvvmAddress;
    }
}
