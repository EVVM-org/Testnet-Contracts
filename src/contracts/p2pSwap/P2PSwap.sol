// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.org/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**
 /$$$$$$$  /$$$$$$ /$$$$$$$  /$$$$$$                                
| $$__  $$/$$__  $| $$__  $$/$$__  $$                               
| $$  \ $|__/  \ $| $$  \ $| $$  \__//$$  /$$  /$$ /$$$$$$  /$$$$$$ 
| $$$$$$$/ /$$$$$$| $$$$$$$|  $$$$$$| $$ | $$ | $$|____  $$/$$__  $$
| $$____/ /$$____/| $$____/ \____  $| $$ | $$ | $$ /$$$$$$| $$  \ $$
| $$     | $$     | $$      /$$  \ $| $$ | $$ | $$/$$__  $| $$  | $$
| $$     | $$$$$$$| $$     |  $$$$$$|  $$$$$/$$$$|  $$$$$$| $$$$$$$/
|__/     |________|__/      \______/ \_____/\___/ \_______| $$____/ 
                                                          | $$      
                                                          | $$      
                                                          |__/      

 * @title P2P Swap Service
 * @author Mate labs  
 * @notice Peer-to-peer decentralized exchange for token trading within the EVVM ecosystem
 * @dev Implements order book-style trading with dynamic market creation, fee distribution,
 *      and integration with EVVM's staking and payment systems. Supports both proportional
 *      and fixed fee models with time-delayed governance for parameter updates.
 * 
 * Key Features:
 * - Dynamic market creation for any token pair
 * - Order management (create, cancel, execute)
 * - Configurable fee structure with multi-party distribution
 * - Service staking capabilities via StakingServiceHooks inheritance
 * - ERC-191 signature verification for all operations
 * - Time-delayed administrative governance
 * 
 * Fee Distribution:
 * - Seller: 50% (configurable)
 * - Service: 40% (configurable) 
 * - Staker Rewards: 10% (configurable)
 */

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/utils/AdvancedStrings.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {StakingServiceUtils} from "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import {SignatureUtils} from "@evvm/testnet-contracts/contracts/p2pSwap/lib/SignatureUtils.sol";

contract P2PSwap is StakingServiceUtils {
    address owner;
    address owner_proposal;
    uint256 owner_timeToAccept;

    address evvmAddress;
    address stakingAddress;

    address constant MATE_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;
    address constant ETH_ADDRESS = 0x0000000000000000000000000000000000000000;

    struct MarketInformation {
        address tokenA;
        address tokenB;
        uint256 maxSlot;
        uint256 ordersAvailable;
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

    struct MetadataMakeOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
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

    Percentage rewardPercentage;
    Percentage rewardPercentage_proposal;
    uint256 rewardPercentage_timeToAcceptNewChange;

    uint256 percentageFee;
    uint256 percentageFee_proposal;
    uint256 percentageFee_timeToAccept;

    uint256 maxLimitFillFixedFee;
    uint256 maxLimitFillFixedFee_proposal;
    uint256 maxLimitFillFixedFee_timeToAccept;

    address tokenToWithdraw;
    uint256 amountToWithdraw;
    address recipientToWithdraw;
    uint256 timeToWithdrawal;

    uint256 marketCount;

    mapping(address user => mapping(uint256 nonce => bool isUsed)) nonceP2PSwap;

    mapping(address tokenA => mapping(address tokenB => uint256 id)) marketId;

    mapping(uint256 id => MarketInformation info) marketMetadata;

    mapping(uint256 idMarket => mapping(uint256 idOrder => Order)) ordersInsideMarket;

    mapping(address => uint256) balancesOfContract;

    constructor(
        address _evvmAddress,
        address _stakingAddress,
        address _owner
    ) StakingServiceUtils(_stakingAddress) {
        evvmAddress = _evvmAddress;
        owner = _owner;
        maxLimitFillFixedFee = 0.001 ether;
        percentageFee = 500;
        rewardPercentage = Percentage({
            seller: 5000,
            service: 4000,
            mateStaker: 1000
        });
        stakingAddress = _stakingAddress;
    }

    function makeOrder(
        address user,
        MetadataMakeOrder memory metadata,
        bytes memory signature,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external returns (uint256 market, uint256 orderId) {
        if (
            !SignatureUtils.verifyMessageSignedForMakeOrder(
                Evvm(evvmAddress).getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.amountA,
                metadata.amountB,
                signature
            )
        ) {
            revert("Invalid signature");
        }

        if (nonceP2PSwap[user][metadata.nonce]) {
            revert("Nonce already used");
        }

        makePay(
            user,
            metadata.tokenA,
            _nonce_Evvm,
            metadata.amountA,
            _priorityFee_Evvm,
            _priority_Evvm,
            _signature_Evvm
        );

        market = findMarket(metadata.tokenA, metadata.tokenB);
        if (market == 0) {
            market = createMarket(metadata.tokenA, metadata.tokenB);
        }

        if (
            marketMetadata[market].maxSlot ==
            marketMetadata[market].ordersAvailable
        ) {
            marketMetadata[market].maxSlot++;
            marketMetadata[market].ordersAvailable++;
            orderId = marketMetadata[market].maxSlot;
        } else {
            for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
                if (ordersInsideMarket[market][i].seller == address(0)) {
                    orderId = i;
                    break;
                }
            }
            marketMetadata[market].ordersAvailable++;
        }

        ordersInsideMarket[market][orderId] = Order(
            user,
            metadata.amountA,
            metadata.amountB
        );

        if (Evvm(evvmAddress).isAddressStaker(msg.sender)) {
            if (_priorityFee_Evvm > 0) {
                // send the executor the priorityFee
                makeCaPay(msg.sender, metadata.tokenA, _priorityFee_Evvm);
            }

            // send some mate token reward to the executor (independent of the priorityFee the user attached)
            makeCaPay(
                msg.sender,
                MATE_TOKEN_ADDRESS,
                _priorityFee_Evvm > 0
                    ? (Evvm(evvmAddress).getRewardAmount() * 3)
                    : (Evvm(evvmAddress).getRewardAmount() * 2)
            );
        }

        nonceP2PSwap[user][metadata.nonce] = true;
    }

    function cancelOrder(
        address user,
        MetadataCancelOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForCancelOrder(
                Evvm(evvmAddress).getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.orderId,
                metadata.signature
            )
        ) {
            revert("Invalid signature");
        }

        uint256 market = findMarket(metadata.tokenA, metadata.tokenB);

        if (nonceP2PSwap[user][metadata.nonce]) {
            revert("Invalid nonce");
        }

        if (
            market == 0 ||
            ordersInsideMarket[market][metadata.orderId].seller != user
        ) {
            revert("Invalid order");
        }

        if (_priorityFee_Evvm > 0) {
            makePay(
                user,
                MATE_TOKEN_ADDRESS,
                _nonce_Evvm,
                0,
                _priorityFee_Evvm,
                _priority_Evvm,
                _signature_Evvm
            );
        }

        makeCaPay(
            user,
            metadata.tokenA,
            ordersInsideMarket[market][metadata.orderId].amountA
        );

        ordersInsideMarket[market][metadata.orderId].seller = address(0);

        if (Evvm(evvmAddress).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                MATE_TOKEN_ADDRESS,
                _priorityFee_Evvm > 0
                    ? ((Evvm(evvmAddress).getRewardAmount() * 3) +
                        _priorityFee_Evvm)
                    : (Evvm(evvmAddress).getRewardAmount() * 2)
            );
        }
        marketMetadata[market].ordersAvailable--;
        nonceP2PSwap[user][metadata.nonce] = true;
    }

    function dispatchOrder_fillPropotionalFee(
        address user,
        MetadataDispatchOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForDispatchOrder(
                Evvm(evvmAddress).getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.orderId,
                metadata.signature
            )
        ) {
            revert("Invalid signature");
        }

        uint256 market = findMarket(metadata.tokenA, metadata.tokenB);

        if (nonceP2PSwap[user][metadata.nonce]) {
            revert("Invalid nonce");
        }

        if (
            market == 0 ||
            ordersInsideMarket[market][metadata.orderId].seller == address(0)
        ) {
            revert("Invalid order");
        }

        uint256 fee = calculateFillPropotionalFee(
            ordersInsideMarket[market][metadata.orderId].amountB
        );

        if (
            metadata.amountOfTokenBToFill <
            ordersInsideMarket[market][metadata.orderId].amountB + fee
        ) {
            revert("Insuficient amountOfTokenToFill");
        }

        makePay(
            user,
            metadata.tokenB,
            _nonce_Evvm,
            metadata.amountOfTokenBToFill,
            _priorityFee_Evvm,
            _priority_Evvm,
            _signature_Evvm
        );

        // si es mas del fee + el monto de la orden hacemos caPay al usuario del sobranate
        if (
            metadata.amountOfTokenBToFill >
            ordersInsideMarket[market][metadata.orderId].amountB + fee
        ) {
            makeCaPay(
                user,
                metadata.tokenB,
                metadata.amountOfTokenBToFill -
                    (ordersInsideMarket[market][metadata.orderId].amountB + fee)
            );
        }

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        uint256 sellerAmount = ordersInsideMarket[market][metadata.orderId]
            .amountB + ((fee * rewardPercentage.seller) / 10_000);
        uint256 executorAmount = _priorityFee_Evvm +
            ((fee * rewardPercentage.mateStaker) / 10_000);

        // pay seller
        toData[0] = EvvmStructs.DisperseCaPayMetadata(
            sellerAmount,
            ordersInsideMarket[market][metadata.orderId].seller
        );
        // pay executor
        toData[1] = EvvmStructs.DisperseCaPayMetadata(
            executorAmount,
            msg.sender
        );

        balancesOfContract[metadata.tokenB] +=
            (fee * rewardPercentage.service) /
            10_000;

        makeDisperseCaPay(
            toData,
            metadata.tokenB,
            toData[0].amount + toData[1].amount
        );

        // pay user with token A
        makeCaPay(
            user,
            metadata.tokenA,
            ordersInsideMarket[market][metadata.orderId].amountA
        );

        if (Evvm(evvmAddress).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                MATE_TOKEN_ADDRESS,
                metadata.amountOfTokenBToFill >
                    ordersInsideMarket[market][metadata.orderId].amountB + fee
                    ? Evvm(evvmAddress).getRewardAmount() * 5
                    : Evvm(evvmAddress).getRewardAmount() * 4
            );
        }

        ordersInsideMarket[market][metadata.orderId].seller = address(0);
        marketMetadata[market].ordersAvailable--;
        nonceP2PSwap[user][metadata.nonce] = true;
    }

    function dispatchOrder_fillFixedFee(
        address user,
        MetadataDispatchOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm,
        uint256 maxFillFixedFee ///@dev for testing purposes
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForDispatchOrder(
                Evvm(evvmAddress).getEvvmID(),
                user,
                metadata.nonce,
                metadata.tokenA,
                metadata.tokenB,
                metadata.orderId,
                metadata.signature
            )
        ) {
            revert("Invalid signature");
        }

        uint256 market = findMarket(metadata.tokenA, metadata.tokenB);

        if (nonceP2PSwap[user][metadata.nonce]) {
            revert("Invalid nonce");
        }

        if (
            market == 0 ||
            ordersInsideMarket[market][metadata.orderId].seller == address(0)
        ) {
            revert("Invalid order");
        }

        (uint256 fee, uint256 fee10) = calculateFillFixedFee(
            ordersInsideMarket[market][metadata.orderId].amountB,
            maxFillFixedFee
        );

        if (
            metadata.amountOfTokenBToFill <
            ordersInsideMarket[market][metadata.orderId].amountB + fee - fee10
        ) {
            revert("Insuficient amountOfTokenBToFill");
        }

        makePay(
            user,
            metadata.tokenB,
            _nonce_Evvm,
            metadata.amountOfTokenBToFill,
            _priorityFee_Evvm,
            _priority_Evvm,
            _signature_Evvm
        );

        uint256 finalFee = metadata.amountOfTokenBToFill >=
            ordersInsideMarket[market][metadata.orderId].amountB +
                fee -
                fee10 &&
            metadata.amountOfTokenBToFill <
            ordersInsideMarket[market][metadata.orderId].amountB + fee
            ? metadata.amountOfTokenBToFill -
                ordersInsideMarket[market][metadata.orderId].amountB
            : fee;

        // si es mas del fee + el monto de la orden hacemos caPay al usuario del sobranate
        if (
            metadata.amountOfTokenBToFill >
            ordersInsideMarket[market][metadata.orderId].amountB + fee
        ) {
            makeCaPay(
                user,
                metadata.tokenB,
                metadata.amountOfTokenBToFill -
                    (ordersInsideMarket[market][metadata.orderId].amountB + fee)
            );
        }

        EvvmStructs.DisperseCaPayMetadata[]
            memory toData = new EvvmStructs.DisperseCaPayMetadata[](2);

        toData[0] = EvvmStructs.DisperseCaPayMetadata(
            ordersInsideMarket[market][metadata.orderId].amountB +
                ((finalFee * rewardPercentage.seller) / 10_000),
            ordersInsideMarket[market][metadata.orderId].seller
        );
        toData[1] = EvvmStructs.DisperseCaPayMetadata(
            _priorityFee_Evvm +
                ((finalFee * rewardPercentage.mateStaker) / 10_000),
            msg.sender
        );

        balancesOfContract[metadata.tokenB] +=
            (finalFee * rewardPercentage.service) /
            10_000;

        makeDisperseCaPay(
            toData,
            metadata.tokenB,
            toData[0].amount + toData[1].amount
        );

        makeCaPay(
            user,
            metadata.tokenA,
            ordersInsideMarket[market][metadata.orderId].amountA
        );

        if (Evvm(evvmAddress).isAddressStaker(msg.sender)) {
            makeCaPay(
                msg.sender,
                MATE_TOKEN_ADDRESS,
                metadata.amountOfTokenBToFill >
                    ordersInsideMarket[market][metadata.orderId].amountB + fee
                    ? Evvm(evvmAddress).getRewardAmount() * 5
                    : Evvm(evvmAddress).getRewardAmount() * 4
            );
        }

        ordersInsideMarket[market][metadata.orderId].seller = address(0);
        marketMetadata[market].ordersAvailable--;
        nonceP2PSwap[user][metadata.nonce] = true;
    }

    //devolver el 0.05% del monto de la orden
    function calculateFillPropotionalFee(
        uint256 amount
    ) internal view returns (uint256 fee) {
        ///@dev get the % of the amount
        fee = (amount * percentageFee) / 10_000;
    }

    function calculateFillFixedFee(
        uint256 amount,
        uint256 maxFillFixedFee
    ) internal view returns (uint256 fee, uint256 fee10) {
        if (calculateFillPropotionalFee(amount) > maxFillFixedFee) {
            fee = maxFillFixedFee;
            fee10 = (fee * 1000) / 10_000;
        } else {
            fee = calculateFillPropotionalFee(amount);
        }
    }

    function createMarket(
        address tokenA,
        address tokenB
    ) internal returns (uint256) {
        marketCount++;
        marketId[tokenA][tokenB] = marketCount;
        marketMetadata[marketCount] = MarketInformation(tokenA, tokenB, 0, 0);
        return marketCount;
    }

    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    // Tools for Evvm
    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢

    function makePay(
        address _user_Evvm,
        address _token_Evvm,
        uint256 _nonce_Evvm,
        uint256 _ammount_Evvm,
        uint256 _priorityFee_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm
    ) internal {
        Evvm(evvmAddress).pay(
            _user_Evvm,
            address(this),
            "",
            _token_Evvm,
            _ammount_Evvm,
            _priorityFee_Evvm,
            _nonce_Evvm,
            _priority_Evvm,
            address(this),
            _signature_Evvm
        );
    }

    function makeCaPay(
        address _user_Evvm,
        address _token_Evvm,
        uint256 _ammount_Evvm
    ) internal {
        Evvm(evvmAddress).caPay(_user_Evvm, _token_Evvm, _ammount_Evvm);
    }

    function makeDisperseCaPay(
        EvvmStructs.DisperseCaPayMetadata[] memory toData,
        address token,
        uint256 amount
    ) internal {
        Evvm(evvmAddress).disperseCaPay(toData, token, amount);
    }

    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    // Admin tools
    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢

    function proposeOwner(address _owner) external {
        if (msg.sender != owner) {
            revert();
        }
        owner_proposal = _owner;
        owner_timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposeOwner() external {
        if (
            msg.sender != owner_proposal || block.timestamp > owner_timeToAccept
        ) {
            revert();
        }
        owner_proposal = address(0);
    }

    function acceptOwner() external {
        if (
            msg.sender != owner_proposal || block.timestamp > owner_timeToAccept
        ) {
            revert();
        }
        owner = owner_proposal;
        owner_proposal = address(0);
    }

    function proposeFillFixedPercentage(
        uint256 _seller,
        uint256 _service,
        uint256 _mateStaker
    ) external {
        if (msg.sender != owner) {
            revert();
        }
        if (_seller + _service + _mateStaker != 10_000) {
            revert();
        }
        rewardPercentage_proposal = Percentage(_seller, _service, _mateStaker);
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 days;
    }

    function rejectProposeFillFixedPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Percentage(0, 0, 0);
    }

    function acceptFillFixedPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage = rewardPercentage_proposal;
    }

    function proposeFillPropotionalPercentage(
        uint256 _seller,
        uint256 _service,
        uint256 _mateStaker
    ) external {
        if (msg.sender != owner || _seller + _service + _mateStaker != 10_000) {
            revert();
        }
        rewardPercentage_proposal = Percentage(_seller, _service, _mateStaker);
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 days;
    }

    function rejectProposeFillPropotionalPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Percentage(0, 0, 0);
    }

    function acceptFillPropotionalPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage = rewardPercentage_proposal;
    }

    function proposePercentageFee(uint256 _percentageFee) external {
        if (msg.sender != owner) {
            revert();
        }
        percentageFee_proposal = _percentageFee;
        percentageFee_timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposePercentageFee() external {
        if (
            msg.sender != owner || block.timestamp > percentageFee_timeToAccept
        ) {
            revert();
        }
        percentageFee_proposal = 0;
    }

    function acceptPercentageFee() external {
        if (
            msg.sender != owner || block.timestamp > percentageFee_timeToAccept
        ) {
            revert();
        }
        percentageFee = percentageFee_proposal;
    }

    function proposeMaxLimitFillFixedFee(
        uint256 _maxLimitFillFixedFee
    ) external {
        if (msg.sender != owner) {
            revert();
        }
        maxLimitFillFixedFee_proposal = _maxLimitFillFixedFee;
        maxLimitFillFixedFee_timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposeMaxLimitFillFixedFee() external {
        if (
            msg.sender != owner ||
            block.timestamp > maxLimitFillFixedFee_timeToAccept
        ) {
            revert();
        }
        maxLimitFillFixedFee_proposal = 0;
    }

    function acceptMaxLimitFillFixedFee() external {
        if (
            msg.sender != owner ||
            block.timestamp > maxLimitFillFixedFee_timeToAccept
        ) {
            revert();
        }
        maxLimitFillFixedFee = maxLimitFillFixedFee_proposal;
    }

    function proposeWithdrawal(
        address _tokenToWithdraw,
        uint256 _amountToWithdraw,
        address _to
    ) external {
        if (
            msg.sender != owner ||
            _amountToWithdraw > balancesOfContract[_tokenToWithdraw]
        ) {
            revert();
        }
        tokenToWithdraw = _tokenToWithdraw;
        amountToWithdraw = _amountToWithdraw;
        recipientToWithdraw = _to;
        timeToWithdrawal = block.timestamp + 1 days;
    }

    function rejectProposeWithdrawal() external {
        if (msg.sender != owner || block.timestamp > timeToWithdrawal) {
            revert();
        }
        tokenToWithdraw = address(0);
        amountToWithdraw = 0;
        recipientToWithdraw = address(0);
        timeToWithdrawal = 0;
    }

    function acceptWithdrawal() external {
        if (msg.sender != owner || block.timestamp > timeToWithdrawal) {
            revert();
        }
        makeCaPay(recipientToWithdraw, tokenToWithdraw, amountToWithdraw);
        balancesOfContract[tokenToWithdraw] -= amountToWithdraw;

        tokenToWithdraw = address(0);
        amountToWithdraw = 0;
        recipientToWithdraw = address(0);
        timeToWithdrawal = 0;
    }

    function stake(uint256 amount) external {
        if (
            msg.sender != owner ||
            amount * Staking(stakingAddress).priceOfStaking() >
            balancesOfContract[0x0000000000000000000000000000000000000001]
        ) revert();

        _makeStakeService(amount);
    }

    function unstake(uint256 amount) external {
        if (msg.sender != owner) revert();

        _makeUnstakeService(amount);
    }

    function addBalance(address _token, uint256 _amount) external {
        if (msg.sender != owner) {
            revert();
        }
        balancesOfContract[_token] += _amount;
    }

    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    //getters
    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    function getAllMarketOrders(
        uint256 market
    ) public view returns (OrderForGetter[] memory orders) {
        orders = new OrderForGetter[](marketMetadata[market].maxSlot + 1);

        for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
            if (ordersInsideMarket[market][i].seller != address(0)) {
                orders[i - 1] = OrderForGetter(
                    market,
                    i,
                    ordersInsideMarket[market][i].seller,
                    ordersInsideMarket[market][i].amountA,
                    ordersInsideMarket[market][i].amountB
                );
            }
        }
        return orders;
    }

    function getOrder(
        uint256 market,
        uint256 orderId
    ) public view returns (Order memory order) {
        order = ordersInsideMarket[market][orderId];
        return order;
    }

    function getMyOrdersInSpecificMarket(
        address user,
        uint256 market
    ) public view returns (OrderForGetter[] memory orders) {
        orders = new OrderForGetter[](marketMetadata[market].maxSlot + 1);

        for (uint256 i = 1; i <= marketMetadata[market].maxSlot + 1; i++) {
            if (ordersInsideMarket[market][i].seller == user) {
                orders[i - 1] = OrderForGetter(
                    market,
                    i,
                    ordersInsideMarket[market][i].seller,
                    ordersInsideMarket[market][i].amountA,
                    ordersInsideMarket[market][i].amountB
                );
            }
        }
        return orders;
    }

    function findMarket(
        address tokenA,
        address tokenB
    ) public view returns (uint256) {
        return marketId[tokenA][tokenB];
    }

    function getMarketMetadata(
        uint256 market
    ) public view returns (MarketInformation memory) {
        return marketMetadata[market];
    }

    function getAllMarketsMetadata()
        public
        view
        returns (MarketInformation[] memory)
    {
        MarketInformation[] memory markets = new MarketInformation[](
            marketCount + 1
        );
        for (uint256 i = 1; i <= marketCount; i++) {
            markets[i - 1] = marketMetadata[i];
        }
        return markets;
    }

    function checkIfANonceP2PSwapIsUsed(
        address user,
        uint256 nonce
    ) public view returns (bool) {
        return nonceP2PSwap[user][nonce];
    }

    function getBalanceOfContract(
        address token
    ) external view returns (uint256) {
        return balancesOfContract[token];
    }

    function getOwnerProposal() external view returns (address) {
        return owner_proposal;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getOwnerTimeToAccept() external view returns (uint256) {
        return owner_timeToAccept;
    }

    function getRewardPercentageProposal()
        external
        view
        returns (Percentage memory)
    {
        return rewardPercentage_proposal;
    }

    function getRewardPercentage() external view returns (Percentage memory) {
        return rewardPercentage;
    }

    function getProposalPercentageFee() external view returns (uint256) {
        return percentageFee_proposal;
    }

    function getPercentageFee() external view returns (uint256) {
        return percentageFee;
    }

    function getMaxLimitFillFixedFeeProposal() external view returns (uint256) {
        return maxLimitFillFixedFee_proposal;
    }

    function getMaxLimitFillFixedFee() external view returns (uint256) {
        return maxLimitFillFixedFee;
    }

    function getProposedWithdrawal()
        external
        view
        returns (address, uint256, address, uint256)
    {
        return (
            tokenToWithdraw,
            amountToWithdraw,
            recipientToWithdraw,
            timeToWithdrawal
        );
    }
}
