// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";
import {IStaking} from "@evvm/testnet-contracts/interfaces/IStaking.sol";
import {SignatureUtil} from "@evvm/testnet-contracts/library/utils/SignatureUtil.sol";
import {AsyncNonceService} from "@evvm/testnet-contracts/library/utils/service/AsyncNonceService.sol";

abstract contract EvvmService is AsyncNonceService {
    error InvalidServiceSignature();

    IEvvm evvm;
    IStaking staking;

    constructor(address evvmAddress, address stakingAddress) {
        evvm = IEvvm(evvmAddress);
        staking = IStaking(stakingAddress);
    }

    function validateServiceSignature(
        string memory functionName,
        string memory inputs,
        bytes memory signature,
        address expectedSigner
    ) internal view virtual {
        if (
            !SignatureUtil.verifySignature(
                evvm.getEvvmID(),
                functionName,
                inputs,
                signature,
                expectedSigner
            )
        ) revert InvalidServiceSignature();
    }

    function requestPay(
        address from,
        address token,
        uint256 amount,
        uint256 priorityFee,
        uint256 nonce,
        bool priorityFlag,
        bytes memory signature
    ) internal virtual {
        evvm.pay(
            from,
            address(this),
            "",
            token,
            amount,
            priorityFee,
            nonce,
            priorityFlag,
            address(this),
            signature
        );
    }

    function makeCaPay(
        address to,
        address token,
        uint256 amount
    ) internal virtual {
        evvm.caPay(to, token, amount);
    }

    function _makeStakeService(uint256 amountToStake) internal {
        staking.prepareServiceStaking(amountToStake);
        evvm.caPay(
            address(staking),
            getPrincipalTokenAddress(),
            staking.priceOfStaking() * amountToStake
        );
        staking.confirmServiceStaking();
    }

    function _makeUnstakeService(uint256 amountToUnstake) internal {
        staking.serviceUnstaking(amountToUnstake);
    }

    function _changeEvvmAddress(address newEvvmAddress) internal {
        evvm = IEvvm(newEvvmAddress);
    }

    function _changeStakingAddress(address newStakingAddress) internal {
        staking = IStaking(newStakingAddress);
    }

    function getPrincipalTokenAddress()
        internal
        pure
        virtual
        returns (address)
    {
        return address(1);
    }

    function getEtherAddress() internal pure virtual returns (address) {
        return address(0);
    }
}
