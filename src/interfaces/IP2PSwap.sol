// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.4;

interface P2PSwap {
    struct MarketInformation {
        address tokenA;
        address tokenB;
        uint256 maxSlot;
        uint256 ordersAvailable;
    }

    struct MetadataCancelOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 orderId;
        bytes signature;
    }

    struct MetadataDispatchOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 orderId;
        uint256 amountOfTokenBToFill;
        bytes signature;
    }

    struct MetadataMakeOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    struct Order {
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    struct OrderForGetter {
        uint256 marketId;
        uint256 orderId;
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    struct Percentage {
        uint256 seller;
        uint256 service;
        uint256 mateStaker;
    }

    function acceptFillFixedPercentage() external;
    function acceptFillPropotionalPercentage() external;
    function acceptMaxLimitFillFixedFee() external;
    function acceptOwner() external;
    function acceptPercentageFee() external;
    function acceptWithdrawal() external;
    function addBalance(address _token, uint256 _amount) external;
    function cancelOrder(
        address user,
        MetadataCancelOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external;
    function checkIfANonceP2PSwapIsUsed(address user, uint256 nonce) external view returns (bool);
    function dispatchOrder_fillFixedFee(
        address user,
        MetadataDispatchOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm,
        uint256 maxFillFixedFee
    ) external;
    function dispatchOrder_fillPropotionalFee(
        address user,
        MetadataDispatchOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external;
    function findMarket(address tokenA, address tokenB) external view returns (uint256);
    function getAllMarketOrders(uint256 market) external view returns (OrderForGetter[] memory orders);
    function getAllMarketsMetadata() external view returns (MarketInformation[] memory);
    function getBalanceOfContract(address token) external view returns (uint256);
    function getMarketMetadata(uint256 market) external view returns (MarketInformation memory);
    function getMaxLimitFillFixedFee() external view returns (uint256);
    function getMaxLimitFillFixedFeeProposal() external view returns (uint256);
    function getMyOrdersInSpecificMarket(address user, uint256 market)
        external
        view
        returns (OrderForGetter[] memory orders);
    function getOrder(uint256 market, uint256 orderId) external view returns (Order memory order);
    function getOwner() external view returns (address);
    function getOwnerProposal() external view returns (address);
    function getOwnerTimeToAccept() external view returns (uint256);
    function getPercentageFee() external view returns (uint256);
    function getProposalPercentageFee() external view returns (uint256);
    function getProposedWithdrawal() external view returns (address, uint256, address, uint256);
    function getRewardPercentage() external view returns (Percentage memory);
    function getRewardPercentageProposal() external view returns (Percentage memory);
    function makeOrder(
        address user,
        MetadataMakeOrder memory metadata,
        bytes memory signature,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external returns (uint256 market, uint256 orderId);
    function proposeFillFixedPercentage(uint256 _seller, uint256 _service, uint256 _mateStaker) external;
    function proposeFillPropotionalPercentage(uint256 _seller, uint256 _service, uint256 _mateStaker) external;
    function proposeMaxLimitFillFixedFee(uint256 _maxLimitFillFixedFee) external;
    function proposeOwner(address _owner) external;
    function proposePercentageFee(uint256 _percentageFee) external;
    function proposeWithdrawal(address _tokenToWithdraw, uint256 _amountToWithdraw, address _to) external;
    function rejectProposeFillFixedPercentage() external;
    function rejectProposeFillPropotionalPercentage() external;
    function rejectProposeMaxLimitFillFixedFee() external;
    function rejectProposeOwner() external;
    function rejectProposePercentageFee() external;
    function rejectProposeWithdrawal() external;
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external;
}
