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
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {SignatureRecover} from "@evvm/testnet-contracts/library/SignatureRecover.sol";
import {SignatureUtils} from "@evvm/testnet-contracts/contracts/p2pSwap/lib/SignatureUtils.sol";
import {AdvancedStrings} from "@evvm/testnet-contracts/library/AdvancedStrings.sol";
import {EvvmStructs} from "@evvm/testnet-contracts/contracts/evvm/lib/EvvmStructs.sol";
import {StakingServiceHooks} from "@evvm/testnet-contracts/library/StakingServiceHooks.sol";

contract P2PSwap is StakingServiceHooks {
    using SignatureRecover for *;
    using AdvancedStrings for *;

    /// @notice Current contract owner with administrative privileges
    address owner;
    /// @notice Proposed new owner address pending acceptance
    address owner_proposal;
    /// @notice Timestamp when the proposed owner change can be accepted
    uint256 owner_timeToAccept;

    /// @notice Address of the EVVM core contract for payment processing
    address evvmAddress;
    /// @notice Address of the Staking contract for service staking functionality
    address stakingAddress;

    /// @notice Constant address representing the MATE token (Principal Token)
    address constant MATE_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;
    /// @notice Constant address representing native ETH
    address constant ETH_ADDRESS = 0x0000000000000000000000000000000000000000;

    /**
     * @notice Market metadata containing token pair and order tracking information
     * @param tokenA Address of the first token in the trading pair
     * @param tokenB Address of the second token in the trading pair
     * @param maxSlot Maximum order ID ever created in this market
     * @param ordersAvailable Current number of active orders in the market
     */
    struct MarketInformation {
        address tokenA;
        address tokenB;
        uint256 maxSlot;
        uint256 ordersAvailable;
    }
    
    /**
     * @notice Individual order details within a market
     * @param seller Address of the user who created the order
     * @param amountA Amount of tokenA the seller is offering
     * @param amountB Amount of tokenB the seller wants in return
     */
    struct Order {
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    /**
     * @notice Extended order information for external queries
     * @param marketId ID of the market containing this order
     * @param orderId Unique order ID within the market
     * @param seller Address of the user who created the order
     * @param amountA Amount of tokenA being offered
     * @param amountB Amount of tokenB being requested
     */
    struct OrderForGetter {
        uint256 marketId;
        uint256 orderId;
        address seller;
        uint256 amountA;
        uint256 amountB;
    }

    /**
     * @notice Fee distribution percentages (in basis points, total must equal 10,000)
     * @param seller Percentage of fees distributed to the order seller
     * @param service Percentage of fees retained by the P2PSwap service
     * @param mateStaker Percentage of fees distributed to MATE token stakers
     */
    struct Percentage {
        uint256 seller;
        uint256 service;
        uint256 mateStaker;
    }

    /**
     * @notice Metadata required for creating a new order
     * @param nonce Unique nonce to prevent replay attacks
     * @param tokenA Address of the token being offered
     * @param tokenB Address of the token being requested
     * @param amountA Amount of tokenA to offer
     * @param amountB Amount of tokenB requested in return
     */
    struct MetadataMakeOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
    }

    /**
     * @notice Metadata required for canceling an existing order
     * @param nonce Unique nonce to prevent replay attacks
     * @param tokenA Address of the first token in the market
     * @param tokenB Address of the second token in the market
     * @param orderId ID of the order to cancel
     * @param signature User's signature authorizing the cancellation
     */
    struct MetadataCancelOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 orderId;
        bytes signature;
    }

    /**
     * @notice Metadata required for executing/filling an order
     * @param nonce Unique nonce to prevent replay attacks
     * @param tokenA Address of the first token in the market
     * @param tokenB Address of the second token in the market
     * @param orderId ID of the order to execute
     * @param amountOfTokenBToFill Amount of tokenB to pay (including fees)
     * @param signature User's signature authorizing the execution
     */
    struct MetadataDispatchOrder {
        uint256 nonce;
        address tokenA;
        address tokenB;
        uint256 orderId;
        uint256 amountOfTokenBToFill;
        bytes signature;
    }

    /// @notice Current fee distribution percentages
    Percentage rewardPercentage;
    /// @notice Proposed new fee distribution percentages
    Percentage rewardPercentage_proposal;
    /// @notice Timestamp when reward percentage change can be accepted
    uint256 rewardPercentage_timeToAcceptNewChange;

    /// @notice Current trading fee percentage (in basis points)
    uint256 percentageFee;
    /// @notice Proposed new trading fee percentage
    uint256 percentageFee_proposal;
    /// @notice Timestamp when fee percentage change can be accepted
    uint256 percentageFee_timeToAccept;

    /// @notice Maximum fixed fee limit for order execution
    uint256 maxLimitFillFixedFee;
    /// @notice Proposed new maximum fixed fee limit
    uint256 maxLimitFillFixedFee_proposal;
    /// @notice Timestamp when max fee limit change can be accepted
    uint256 maxLimitFillFixedFee_timeToAccept;

    /// @notice Token address for pending withdrawal
    address tokenToWithdraw;
    /// @notice Amount for pending withdrawal
    uint256 amountToWithdraw;
    /// @notice Recipient address for pending withdrawal
    address recipientToWithdraw;
    /// @notice Timestamp when withdrawal can be executed
    uint256 timeToWithdrawal;

    /// @notice Total number of markets created
    uint256 marketCount;

    /// @notice Tracks used nonces per user to prevent replay attacks
    mapping(address user => mapping(uint256 nonce => bool isUsed)) nonceP2PSwap;

    /// @notice Maps token pairs to their market ID
    mapping(address tokenA => mapping(address tokenB => uint256 id)) marketId;

    /// @notice Stores market information by market ID
    mapping(uint256 id => MarketInformation info) marketMetadata;

    /// @notice Stores orders within each market
    mapping(uint256 idMarket => mapping(uint256 idOrder => Order)) ordersInsideMarket;

    /// @notice Tracks service fee balances accumulated per token
    mapping(address => uint256) balancesOfContract;

    /**
     * @notice Initializes the P2PSwap contract with required addresses and default parameters
     * @param _evvmAddress Address of the EVVM core contract for payment processing
     * @param _stakingAddress Address of the Staking contract for service functionality
     * @param _owner Address that will have administrative privileges
     */
    constructor(
        address _evvmAddress,
        address _stakingAddress,
        address _owner
    ) StakingServiceHooks(_stakingAddress) {
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

    /**
     * @notice Creates a new trading order in the specified market
     * @dev Verifies signature, processes payment, creates/finds market, and assigns order slot
     * @param user Address of the user creating the order
     * @param metadata Order details including tokens, amounts, and nonce
     * @param signature User's signature authorizing the order creation
     * @param _priorityFee_Evvm Priority fee for EVVM transaction processing
     * @param _nonce_Evvm Nonce for EVVM payment transaction
     * @param _priority_Evvm Whether to use priority (async) processing
     * @param _signature_Evvm Signature for EVVM payment authorization
     * @return market ID of the market where order was created
     * @return orderId Unique ID of the created order within the market
     */
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

    /**
     * @notice Cancels an existing order and refunds tokens to the seller
     * @dev Verifies signature, validates ownership, refunds tokenA, and removes order
     * @param user Address of the user canceling the order
     * @param metadata Cancel details including market info and order ID
     * @param _priorityFee_Evvm Priority fee for EVVM transaction (optional)
     * @param _nonce_Evvm Nonce for EVVM payment transaction (if priority fee > 0)
     * @param _priority_Evvm Whether to use priority processing
     * @param _signature_Evvm Signature for EVVM payment (if priority fee > 0)
     */
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

    /**
     * @notice Executes an order using proportional fee calculation
     * @dev Calculates fee as percentage of order amount, distributes payments to all parties
     * @param user Address of the user filling the order
     * @param metadata Execution details including order ID and payment amount
     * @param _priorityFee_Evvm Priority fee for EVVM transaction processing
     * @param _nonce_Evvm Nonce for EVVM payment transaction
     * @param _priority_Evvm Whether to use priority (async) processing
     * @param _signature_Evvm Signature for EVVM payment authorization
     */
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
            revert();
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

    /**
     * @notice Executes an order using fixed fee calculation with maximum limits
     * @dev Calculates fee with upper bound, distributes payments, handles overpayment refunds
     * @param user Address of the user filling the order
     * @param metadata Execution details including order ID and payment amount
     * @param _priorityFee_Evvm Priority fee for EVVM transaction processing
     * @param _nonce_Evvm Nonce for EVVM payment transaction
     * @param _priority_Evvm Whether to use priority (async) processing
     * @param _signature_Evvm Signature for EVVM payment authorization
     * @param maxFillFixedFee Maximum output amount for fee calculation (testing parameter)
     */
    function dispatchOrder_fillFixedFee(
        address user,
        MetadataDispatchOrder memory metadata,
        uint256 _priorityFee_Evvm,
        uint256 _nonce_Evvm,
        bool _priority_Evvm,
        bytes memory _signature_Evvm,
        uint256 maxFillFixedFee
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
            revert();
        }

        uint256 market = findMarket(metadata.tokenA, metadata.tokenB);

        if (nonceP2PSwap[user][metadata.nonce]) {
            revert();
        }

        if (
            market == 0 ||
            ordersInsideMarket[market][metadata.orderId].seller == address(0)
        ) {
            revert();
        }

        (uint256 fee, uint256 fee10) = calculateFillFixedFee(
            ordersInsideMarket[market][metadata.orderId].amountB,
            maxFillFixedFee
        );

        if (
            metadata.amountOfTokenBToFill <
            ordersInsideMarket[market][metadata.orderId].amountB + fee - fee10
        ) {
            revert();
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

    /**
     * @notice Calculates proportional trading fee as percentage of order amount
     * @dev Fee is calculated as (amount * percentageFee) / 10,000 basis points
     * @param amount The order amount to calculate fee for
     * @return fee The calculated proportional fee amount
     */
    function calculateFillPropotionalFee(
        uint256 amount
    ) internal view returns (uint256 fee) {
        fee = (amount * percentageFee) / 10_000;
    }

    /**
     * @notice Calculates fixed trading fee with maximum limit constraints
     * @dev Compares proportional fee with maximum output, applies 10% reduction if needed
     * @param amount Order amount for proportional fee calculation
     * @param maxFillFixedFee Maximum output amount for fee limiting
     * @return fee The final calculated fee amount
     * @return fee10 10% of the fee amount for specific calculations
     */
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

    /**
     * @notice Creates a new trading market for a token pair
     * @dev Increments market count, assigns market ID, initializes market metadata
     * @param tokenA Address of the first token in the trading pair
     * @param tokenB Address of the second token in the trading pair
     * @return The newly created market ID
     */
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

    /**
     * @notice Internal function to process payments through EVVM contract
     * @dev Calls EVVM.pay() with all necessary parameters for token transfer
     * @param _user_Evvm Address of the user making the payment
     * @param _token_Evvm Address of the token being transferred
     * @param _nonce_Evvm Nonce for the EVVM transaction
     * @param _ammount_Evvm Amount of tokens to transfer
     * @param _priorityFee_Evvm Additional priority fee for the transaction
     * @param _priority_Evvm Whether to use priority (async) processing
     * @param _signature_Evvm User's signature authorizing the payment
     */
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

    /**
     * @notice Internal function to distribute tokens from contract balance via EVVM
     * @dev Calls EVVM.caPay() to transfer tokens from P2PSwap to specified user
     * @param _user_Evvm Address of the recipient
     * @param _token_Evvm Address of the token to transfer
     * @param _ammount_Evvm Amount of tokens to transfer
     */
    function makeCaPay(
        address _user_Evvm,
        address _token_Evvm,
        uint256 _ammount_Evvm
    ) internal {
        Evvm(evvmAddress).caPay(_user_Evvm, _token_Evvm, _ammount_Evvm);
    }

    /**
     * @notice Internal function to distribute tokens to multiple recipients via EVVM
     * @dev Calls EVVM.disperseCaPay() for efficient batch token distribution
     * @param toData Array of recipient addresses and amounts
     * @param token Address of the token to distribute
     * @param amount Total amount being distributed (must match sum of individual amounts)
     */
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

    /**
     * @notice Proposes a new contract owner with 1-day delay
     * @dev Only current owner can propose, starts time-delayed governance process
     * @param _owner Address of the proposed new owner
     */
    function proposeOwner(address _owner) external {
        if (msg.sender != owner) {
            revert();
        }
        owner_proposal = _owner;
        owner_timeToAccept = block.timestamp + 1 minutes;
    }

    /**
     * @notice Rejects the current owner change proposal
     * @dev Only proposed owner can reject before deadline expires
     */
    function rejectProposeOwner() external {
        if (
            msg.sender != owner_proposal || block.timestamp > owner_timeToAccept
        ) {
            revert();
        }
        owner_proposal = address(0);
    }

    /**
     * @notice Accepts ownership transfer after time delay
     * @dev Only proposed owner can accept after 1-day waiting period
     */
    function acceptOwner() external {
        if (
            msg.sender != owner_proposal || block.timestamp > owner_timeToAccept
        ) {
            revert();
        }
        owner = owner_proposal;
        owner_proposal = address(0);
    }

    /**
     * @notice Proposes new fee distribution percentages for fixed fee model
     * @dev Percentages must sum to 10,000 basis points (100%)
     * @param _seller Percentage for order sellers (basis points)
     * @param _service Percentage for P2PSwap service (basis points)
     * @param _mateStaker Percentage for MATE token stakers (basis points)
     */
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
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 minutes;
    }

    /**
     * @notice Rejects the current fee percentage proposal for fixed fee model
     * @dev Only owner can reject before deadline expires, resets proposal to zero
     */
    function rejectProposeFillFixedPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Percentage(0, 0, 0);
    }

    /**
     * @notice Accepts the fee percentage proposal for fixed fee model after time delay
     * @dev Only owner can accept after 1-day waiting period, applies new percentages
     */
    function acceptFillFixedPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage = rewardPercentage_proposal;
    }

    /**
     * @notice Proposes new fee distribution percentages for proportional fee model
     * @dev Percentages must sum to 10,000 basis points (100%)
     * @param _seller Percentage for order sellers (basis points)
     * @param _service Percentage for P2PSwap service (basis points)
     * @param _mateStaker Percentage for MATE token stakers (basis points)
     */
    function proposeFillPropotionalPercentage(
        uint256 _seller,
        uint256 _service,
        uint256 _mateStaker
    ) external {
        if (msg.sender != owner || _seller + _service + _mateStaker != 10_000) {
            revert();
        }
        rewardPercentage_proposal = Percentage(_seller, _service, _mateStaker);
        rewardPercentage_timeToAcceptNewChange = block.timestamp + 1 minutes;
    }

    /**
     * @notice Rejects the current fee percentage proposal for proportional fee model
     * @dev Only owner can reject before deadline expires, resets proposal to zero
     */
    function rejectProposeFillPropotionalPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage_proposal = Percentage(0, 0, 0);
    }

    /**
     * @notice Accepts the fee percentage proposal for proportional fee model after time delay
     * @dev Only owner can accept after 1-day waiting period, applies new percentages
     */
    function acceptFillPropotionalPercentage() external {
        if (
            msg.sender != owner ||
            block.timestamp > rewardPercentage_timeToAcceptNewChange
        ) {
            revert();
        }
        rewardPercentage = rewardPercentage_proposal;
    }

    /**
     * @notice Proposes a new percentage fee for proportional fee calculation
     * @dev Only owner can propose, starts time-delayed governance process
     * @param _percentageFee New percentage fee value in basis points
     */
    function proposePercentageFee(uint256 _percentageFee) external {
        if (msg.sender != owner) {
            revert();
        }
        percentageFee_proposal = _percentageFee;
        percentageFee_timeToAccept = block.timestamp + 1 minutes;
    }

    /**
     * @notice Rejects the current percentage fee proposal
     * @dev Only owner can reject before deadline expires, resets proposal to zero
     */
    function rejectProposePercentageFee() external {
        if (
            msg.sender != owner || block.timestamp > percentageFee_timeToAccept
        ) {
            revert();
        }
        percentageFee_proposal = 0;
    }

    /**
     * @notice Accepts the percentage fee proposal after time delay
     * @dev Only owner can accept after 1-day waiting period, applies new fee
     */
    function acceptPercentageFee() external {
        if (
            msg.sender != owner || block.timestamp > percentageFee_timeToAccept
        ) {
            revert();
        }
        percentageFee = percentageFee_proposal;
    }

    /**
     * @notice Proposes a new maximum limit for fixed fee calculations
     * @dev Only owner can propose, starts time-delayed governance process
     * @param _maxLimitFillFixedFee New maximum limit value for fixed fee calculations
     */
    function proposeMaxLimitFillFixedFee(
        uint256 _maxLimitFillFixedFee
    ) external {
        if (msg.sender != owner) {
            revert();
        }
        maxLimitFillFixedFee_proposal = _maxLimitFillFixedFee;
        maxLimitFillFixedFee_timeToAccept = block.timestamp + 1 minutes;
    }

    /**
     * @notice Rejects the current maximum limit proposal for fixed fees
     * @dev Only owner can reject before deadline expires, resets proposal to zero
     */
    function rejectProposeMaxLimitFillFixedFee() external {
        if (
            msg.sender != owner ||
            block.timestamp > maxLimitFillFixedFee_timeToAccept
        ) {
            revert();
        }
        maxLimitFillFixedFee_proposal = 0;
    }

    /**
     * @notice Accepts the maximum limit proposal for fixed fees after time delay
     * @dev Only owner can accept after 1-day waiting period, applies new limit
     */
    function acceptMaxLimitFillFixedFee() external {
        if (
            msg.sender != owner ||
            block.timestamp > maxLimitFillFixedFee_timeToAccept
        ) {
            revert();
        }
        maxLimitFillFixedFee = maxLimitFillFixedFee_proposal;
    }

    /**
     * @notice Proposes withdrawal of accumulated service fees
     * @dev Only owner can propose, amount must not exceed available balance
     * @param _tokenToWithdraw Address of token to withdraw
     * @param _amountToWithdraw Amount of tokens to withdraw
     * @param _to Recipient address for the withdrawal
     */
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
        timeToWithdrawal = block.timestamp + 1 minutes;
    }

    /**
     * @notice Rejects the current withdrawal proposal
     * @dev Only owner can reject before deadline expires, clears all withdrawal data
     */
    function rejectProposeWithdrawal() external {
        if (msg.sender != owner || block.timestamp > timeToWithdrawal) {
            revert();
        }
        tokenToWithdraw = address(0);
        amountToWithdraw = 0;
        recipientToWithdraw = address(0);
        timeToWithdrawal = 0;
    }

    /**
     * @notice Executes the withdrawal proposal after time delay
     * @dev Transfers tokens via EVVM, updates balance, and clears withdrawal data
     */
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

    /**
     * @notice Stakes accumulated MATE tokens using service staking functionality
     * @dev Only owner can stake, requires sufficient MATE token balance
     * @param amount Number of staking tokens to stake (not MATE token amount)
     */
    function stake(uint256 amount) external {
        if (
            msg.sender != owner ||
            amount * Staking(stakingAddress).priceOfStaking() >
            balancesOfContract[0x0000000000000000000000000000000000000001]
        ) revert();

        _makeStakeService(amount);
    }

    /**
     * @notice Unstakes service staking tokens and receives MATE tokens
     * @dev Only owner can unstake, subject to staking contract time locks
     * @param amount Number of staking tokens to unstake
     */
    function unstake(uint256 amount) external {
        if (msg.sender != owner) revert();

        _makeUnstakeService(amount);
    }

    /**
     * @notice Manually adds balance to the contract for a specific token
     * @dev Only owner can add balance, useful for reconciling accounting discrepancies
     * @param _token Address of the token to add balance for
     * @param _amount Amount to add to the contract's balance tracking
     */
    function addBalance(address _token, uint256 _amount) external {
        if (msg.sender != owner) {
            revert();
        }
        balancesOfContract[_token] += _amount;
    }

    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    //getters
    //◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢◤◢
    /**
     * @notice Retrieves all active orders in a specific market
     * @dev Returns array with extended order information including market and order IDs
     * @param market The market ID to query orders from
     * @return orders Array of OrderForGetter structs containing all active orders
     */
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

    /**
     * @notice Retrieves a specific order by market and order ID
     * @param market The market ID containing the order
     * @param orderId The specific order ID to retrieve
     * @return order The Order struct containing seller address and amounts
     */
    function getOrder(
        uint256 market,
        uint256 orderId
    ) public view returns (Order memory order) {
        order = ordersInsideMarket[market][orderId];
        return order;
    }

    /**
     * @notice Retrieves all orders from a specific user in a specific market
     * @dev Returns array with extended order information for user's orders only
     * @param user Address of the user whose orders to retrieve
     * @param market The market ID to query orders from
     * @return orders Array of OrderForGetter structs containing user's orders in the market
     */
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

    /**
     * @notice Finds the market ID for a specific token pair
     * @param tokenA Address of the first token
     * @param tokenB Address of the second token
     * @return The market ID for the token pair, or 0 if market doesn't exist
     */
    function findMarket(
        address tokenA,
        address tokenB
    ) public view returns (uint256) {
        return marketId[tokenA][tokenB];
    }

    /**
     * @notice Retrieves metadata information for a specific market
     * @param market The market ID to get metadata for
     * @return MarketInformation struct containing token addresses, max slot, and other metadata
     */
    function getMarketMetadata(
        uint256 market
    ) public view returns (MarketInformation memory) {
        return marketMetadata[market];
    }

    /**
     * @notice Retrieves metadata information for all existing markets
     * @dev Returns array of all market metadata from market ID 1 to marketCount
     * @return Array of MarketInformation structs containing all markets data
     */
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

    /**
     * @notice Checks if a nonce has been used by a specific user
     * @dev Used to prevent replay attacks in P2P swap operations
     * @param user Address of the user to check
     * @param nonce The nonce value to verify
     * @return True if nonce has been used, false otherwise
     */
    function checkIfANonceP2PSwapIsUsed(
        address user,
        uint256 nonce
    ) public view returns (bool) {
        return nonceP2PSwap[user][nonce];
    }

    /**
     * @notice Returns the accumulated service fee balance for a specific token
     * @param token Address of the token to check balance for
     * @return The accumulated balance of the specified token
     */
    function getBalanceOfContract(
        address token
    ) external view returns (uint256) {
        return balancesOfContract[token];
    }

    /**
     * @notice Returns the currently proposed new owner address
     * @return Address of the proposed owner, or address(0) if no proposal exists
     */
    function getOwnerProposal() external view returns (address) {
        return owner_proposal;
    }

    /**
     * @notice Returns the current contract owner address
     * @return Address of the current contract owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
     * @notice Returns the deadline timestamp for accepting ownership transfer
     * @return Timestamp until which the ownership proposal can be accepted
     */
    function getOwnerTimeToAccept() external view returns (uint256) {
        return owner_timeToAccept;
    }

    /**
     * @notice Returns the currently proposed reward percentage distribution
     * @return Percentage struct with proposed seller, service, and staker percentages
     */
    function getRewardPercentageProposal()
        external
        view
        returns (Percentage memory)
    {
        return rewardPercentage_proposal;
    }

    /**
     * @notice Returns the current active reward percentage distribution
     * @return Percentage struct with active seller, service, and staker percentages
     */
    function getRewardPercentage() external view returns (Percentage memory) {
        return rewardPercentage;
    }

    /**
     * @notice Returns the currently proposed percentage fee value
     * @return Proposed percentage fee in basis points for proportional fee calculation
     */
    function getProposalPercentageFee() external view returns (uint256) {
        return percentageFee_proposal;
    }

    /**
     * @notice Returns the current active percentage fee value
     * @return Active percentage fee in basis points for proportional fee calculation
     */
    function getPercentageFee() external view returns (uint256) {
        return percentageFee;
    }

    /**
     * @notice Returns the currently proposed maximum limit for fixed fee calculations
     * @return Proposed maximum limit value for fixed fee model
     */
    function getMaxLimitFillFixedFeeProposal() external view returns (uint256) {
        return maxLimitFillFixedFee_proposal;
    }

    /**
     * @notice Returns the current active maximum limit for fixed fee calculations
     * @return Active maximum limit value for fixed fee model
     */
    function getMaxLimitFillFixedFee() external view returns (uint256) {
        return maxLimitFillFixedFee;
    }

    /**
     * @notice Returns complete information about the current withdrawal proposal
     * @dev Returns all withdrawal parameters including token, amount, recipient, and deadline
     * @return tokenToWithdraw Address of token to be withdrawn
     * @return amountToWithdraw Amount of tokens to be withdrawn
     * @return recipientToWithdraw Address that will receive the tokens
     * @return timeToWithdrawal Deadline timestamp for accepting the withdrawal
     */
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
