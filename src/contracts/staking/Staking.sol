// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;
/**


  /$$$$$$  /$$             /$$      /$$                  
 /$$__  $$| $$            | $$     |__/                  
| $$  \__/$$$$$$   /$$$$$$| $$   /$$/$$/$$$$$$$  /$$$$$$ 
|  $$$$$|_  $$_/  |____  $| $$  /$$| $| $$__  $$/$$__  $$
 \____  $$| $$     /$$$$$$| $$$$$$/| $| $$  \ $| $$  \ $$
 /$$  \ $$| $$ /$$/$$__  $| $$_  $$| $| $$  | $| $$  | $$
|  $$$$$$/|  $$$$|  $$$$$$| $$ \  $| $| $$  | $|  $$$$$$$
 \______/  \___/  \_______|__/  \__|__|__/  |__/\____  $$
                                                /$$  \ $$
                                               |  $$$$$$/
                                                \______/                                                                                       

████████╗███████╗███████╗████████╗███╗   ██╗███████╗████████╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝████╗  ██║██╔════╝╚══██╔══╝
   ██║   █████╗  ███████╗   ██║   ██╔██╗ ██║█████╗     ██║   
   ██║   ██╔══╝  ╚════██║   ██║   ██║╚██╗██║██╔══╝     ██║   
   ██║   ███████╗███████║   ██║   ██║ ╚████║███████╗   ██║   
   ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚══════╝   ╚═╝   
 * @title Staking Mate contract
 * @author jistro.eth ariutokintumi.eth
 * @notice This contract manages the staking mechanism for the EVVM ecosystem
 * @dev Handles presale staking, public staking, and service staking with time locks and signature verification
 *
 * The contract supports three types of staking:
 * 1. Golden Staking: Exclusive to the goldenFisher address
 * 2. Presale Staking: Limited to 800 presale users with 2 staking token limit
 * 3. Public Staking: Open to all users when enabled
 * 4. Service Staking: Allows smart contracts to stake on behalf of users
 *
 * Key features:
 * - Time-locked unstaking mechanisms
 * - Signature-based authorization
 * - Integration with EVVM core contract for payments and rewards
 * - Estimator integration for yield calculations
 */

import {Evvm} from "@EVVM/testnet/contracts/evvm/Evvm.sol";
import {NameService} from "@EVVM/testnet/contracts/nameService/NameService.sol";
import {Estimator} from "@EVVM/testnet/contracts/staking/Estimator.sol";
import {ErrorsLib} from "@EVVM/testnet/contracts/staking/lib/ErrorsLib.sol";
import {SignatureUtils} from "@EVVM/testnet/contracts/staking/lib/SignatureUtils.sol";

contract Staking {
    /**
     * @dev Metadata for presale stakers
     * @param isAllow Whether the address is allowed to participate in presale staking
     * @param stakingAmount Current number of staking tokens staked (max 2 for presale)
     */
    struct presaleStakerMetadata {
        bool isAllow;
        uint256 stakingAmount;
    }

    /**
     * @dev Struct to store the history of the user
     * @param transactionType Type of transaction:
     *          - 0x01 for staking
     *          - 0x02 for unstaking
     *          - Other values for yield/reward transactions
     * @param amount Amount of staking staked/unstaked or reward received
     * @param timestamp Timestamp when the transaction occurred
     * @param totalStaked Total amount of staking currently staked after this transaction
     */
    struct HistoryMetadata {
        bytes32 transactionType;
        uint256 amount;
        uint256 timestamp;
        uint256 totalStaked;
    }

    /**
     * @dev Struct for managing address change proposals with time delay
     * @param actual Current active address
     * @param proposal Proposed new address
     * @param timeToAccept Timestamp when the proposal can be accepted
     */
    struct AddressTypeProposal {
        address actual;
        address proposal;
        uint256 timeToAccept;
    }

    /**
     * @dev Struct for managing uint256 change proposals with time delay
     * @param actual Current active value
     * @param proposal Proposed new value
     * @param timeToAccept Timestamp when the proposal can be accepted
     */
    struct UintTypeProposal {
        uint256 actual;
        uint256 proposal;
        uint256 timeToAccept;
    }

    /**
     * @dev Struct for managing boolean flag changes with time delay
     * @param flag Current boolean state
     * @param timeToAccept Timestamp when the flag change can be executed
     */
    struct BoolTypeProposal {
        bool flag;
        uint256 timeToAccept;
    }

    /// @dev Address of the EVVM core contract
    address private EVVM_ADDRESS;

    /// @dev Maximum number of presale stakers allowed
    uint256 private constant LIMIT_PRESALE_STAKER = 800;
    /// @dev Current count of registered presale stakers
    uint256 private presaleStakerCount;
    /// @dev Price of one staking main token (5083 main token = 1 staking)
    uint256 private constant PRICE_OF_STAKING = 5083 * (10 ** 18);

    /// @dev Admin address management with proposal system
    AddressTypeProposal private admin;
    /// @dev Golden Fisher address management with proposal system
    AddressTypeProposal private goldenFisher;
    /// @dev Estimator contract address management with proposal system
    AddressTypeProposal private estimator;
    /// @dev Time delay for regular staking after unstaking
    UintTypeProposal private secondsToUnlockStaking;
    /// @dev Time delay for full unstaking (21 days default)
    UintTypeProposal private secondsToUnllockFullUnstaking;
    /// @dev Flag to enable/disable presale staking
    BoolTypeProposal private allowPresaleStaking;
    /// @dev Flag to enable/disable public staking
    BoolTypeProposal private allowPublicStaking;

    /// @dev Address representing the principal Principal Token
    address private constant PRINCIPAL_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    /// @dev One-time setup breaker for estimator and EVVM addresses
    bytes1 private breakerSetupEstimatorAndEvvm;

    /// @dev Mapping to track used nonces for staking operations per user
    mapping(address => mapping(uint256 => bool)) private stakingNonce;

    /// @dev Mapping to store presale staker metadata
    mapping(address => presaleStakerMetadata) private userPresaleStaker;

    /// @dev Mapping to store complete staking history for each user
    mapping(address => HistoryMetadata[]) private userHistory;

    /// @dev Modifier to restrict access to admin functions
    modifier onlyOwner() {
        if (msg.sender != admin.actual) revert ErrorsLib.SenderIsNotAdmin();

        _;
    }

    /**
     * @notice Contract constructor
     * @dev Initializes the staking contract with admin and golden fisher addresses
     * @param initialAdmin Address that will have admin privileges
     * @param initialGoldenFisher Address that will have golden fisher privileges
     */
    constructor(address initialAdmin, address initialGoldenFisher) {
        admin.actual = initialAdmin;

        goldenFisher.actual = initialGoldenFisher;

        allowPublicStaking.flag = true;
        allowPresaleStaking.flag = false;

        secondsToUnlockStaking.actual = 0;

        secondsToUnllockFullUnstaking.actual = 21 days;

        breakerSetupEstimatorAndEvvm = 0x01;
    }

    /**
     * @notice One-time setup function for estimator and EVVM addresses
     * @dev Can only be called once during contract initialization
     * @param _estimator Address of the Estimator contract
     * @param _evvm Address of the EVVM core contract
     */
    function _setupEstimatorAndEvvm(
        address _estimator,
        address _evvm
    ) external {
        if (breakerSetupEstimatorAndEvvm == 0x00) revert();

        estimator.actual = _estimator;
        EVVM_ADDRESS = _evvm;
        breakerSetupEstimatorAndEvvm = 0x00;
    }

    /**
     * @notice Allows the golden fisher to stake/unstake with synchronized EVVM nonces
     * @dev Only the golden fisher address can call this function
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function goldenStaking(
        bool isStaking,
        uint256 amountOfStaking,
        bytes memory signature_EVVM
    ) external {
        if (msg.sender != goldenFisher.actual)
            revert ErrorsLib.SenderIsNotGoldenFisher();

        stakingUserProcess(
            goldenFisher.actual,
            amountOfStaking,
            isStaking,
            0,
            Evvm(EVVM_ADDRESS).getNextCurrentSyncNonce(msg.sender),
            false,
            signature_EVVM
        );
    }

    /**
     * @notice Allows presale users to stake/unstake with a limit of 2 staking tokens
     * @dev Only registered presale users can call this function when presale staking is enabled
     * @param user Address of the user performing the staking operation
     * @param isStaking True for staking, false for unstaking
     * @param nonce Unique nonce for this staking operation
     * @param signature Signature proving authorization for this staking operation
     * @param priorityFee_EVVM Priority fee for the EVVM transaction
     * @param nonce_EVVM Nonce for the EVVM contract transaction
     * @param priorityFlag_EVVM True for async EVVM transaction, false for sync
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function presaleStaking(
        address user,
        bool isStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external {
        if (
            !SignatureUtils.verifyMessageSignedForStake(
                Evvm(EVVM_ADDRESS).getEvvmID(),
                user,
                false,
                isStaking,
                1,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnStaking();

        if (checkIfStakeNonceUsed(user, nonce))
            revert ErrorsLib.StakingNonceAlreadyUsed();

        presaleClaims(isStaking, user);

        if (!allowPresaleStaking.flag)
            revert ErrorsLib.PresaleStakingDisabled();

        stakingUserProcess(
            user,
            1,
            isStaking,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        stakingNonce[user][nonce] = true;
    }

    /**
     * @notice Internal function to manage presale staking limits and permissions
     * @dev Enforces the 2 staking token limit for presale users and tracks staking amounts
     * @param _isStaking True for staking (increments count), false for unstaking (decrements count)
     * @param _user Address of the presale user
     */
    function presaleClaims(bool _isStaking, address _user) internal {
        if (allowPublicStaking.flag) {
            revert ErrorsLib.PresaleStakingDisabled();
        } else {
            if (userPresaleStaker[_user].isAllow) {
                if (_isStaking) {
                    // staking

                    if (userPresaleStaker[_user].stakingAmount >= 2)
                        revert ErrorsLib.UserPresaleStakerLimitExceeded();

                    userPresaleStaker[_user].stakingAmount++;
                } else {
                    // unstaking

                    if (userPresaleStaker[_user].stakingAmount == 0)
                        revert ErrorsLib.UserPresaleStakerLimitExceeded();

                    userPresaleStaker[_user].stakingAmount--;
                }
            } else {
                revert ErrorsLib.UserIsNotPresaleStaker();
            }
        }
    }

    /**
     * @notice Allows any user to stake/unstake when public staking is enabled
     * @dev Requires signature verification and handles nonce management
     * @param user Address of the user performing the staking operation
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param nonce Unique nonce for this staking operation
     * @param signature Signature proving authorization for this staking operation
     * @param priorityFee_EVVM Priority fee for the EVVM transaction
     * @param nonce_EVVM Nonce for the EVVM contract transaction
     * @param priorityFlag_EVVM True for async EVVM transaction, false for sync
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function publicStaking(
        address user,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external {
        if (!allowPublicStaking.flag) {
            revert();
        }

        if (
            !SignatureUtils.verifyMessageSignedForStake(
                Evvm(EVVM_ADDRESS).getEvvmID(),
                user,
                true,
                isStaking,
                amountOfStaking,
                nonce,
                signature
            )
        ) revert ErrorsLib.InvalidSignatureOnStaking();

        if (checkIfStakeNonceUsed(user, nonce))
            revert ErrorsLib.StakingNonceAlreadyUsed();

        stakingUserProcess(
            user,
            amountOfStaking,
            isStaking,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );

        stakingNonce[user][nonce] = true;
    }

    /**
     * @notice Allows smart contracts (services) to stake on behalf of users
     * @dev Verifies that the service address has contract code and handles service-specific logic
     * @param user Address of the user who owns the stake
     * @param service Address of the smart contract performing the staking
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param nonce Unique nonce for this staking operation
     * @param signature Signature proving authorization for service staking
     * @param priorityFee_EVVM Priority fee for the EVVM transaction (only for staking)
     * @param nonce_EVVM Nonce for the EVVM contract transaction (only for staking)
     * @param priorityFlag_EVVM Priority flag for EVVM transaction (only for staking)
     * @param signature_EVVM Signature for the EVVM contract transaction (only for staking)
     */
    function publicServiceStaking(
        address user,
        address service,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 nonce,
        bytes memory signature,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) external {
        if (!allowPublicStaking.flag) revert ErrorsLib.PublicStakingDisabled();

        uint256 size;

        assembly {
            /// @dev check the size of the opcode of the address
            size := extcodesize(service)
        }

        if (size == 0) revert ErrorsLib.AddressIsNotAService();

        if (isStaking) {
            if (
                !SignatureUtils.verifyMessageSignedForPublicServiceStake(
                    Evvm(EVVM_ADDRESS).getEvvmID(),
                    user,
                    service,
                    isStaking,
                    amountOfStaking,
                    nonce,
                    signature
                )
            ) revert ErrorsLib.InvalidSignatureOnStaking();
        } else {
            if (service != user) revert ErrorsLib.UserAndServiceMismatch();
        }

        if (checkIfStakeNonceUsed(user, nonce))
            revert ErrorsLib.StakingNonceAlreadyUsed();

        stakingServiceProcess(
            user,
            service,
            isStaking,
            amountOfStaking,
            isStaking ? priorityFee_EVVM : 0,
            isStaking ? nonce_EVVM : 0,
            isStaking ? priorityFlag_EVVM : false,
            isStaking ? signature_EVVM : bytes("")
        );

        stakingNonce[user][nonce] = true;
    }

    /**
     * @notice Internal function to process service staking operations
     * @dev Wrapper function that calls the base staking process for service operations
     * @param user Address of the user who owns the stake
     * @param service Address of the smart contract performing the staking
     * @param isStaking True for staking, false for unstaking
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param priorityFee_EVVM Priority fee for the EVVM transaction
     * @param nonce_EVVM Nonce for the EVVM contract transaction
     * @param priorityFlag_EVVM Priority flag for EVVM transaction
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function stakingServiceProcess(
        address user,
        address service,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) internal {
        stakingBaseProcess(
            user,
            service,
            isStaking,
            amountOfStaking,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );
    }

    /**
     * @notice Internal function to process user staking operations
     * @dev Wrapper function that calls the base staking process for user operations
     * @param user Address of the user performing the staking operation
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param isStaking True for staking, false for unstaking
     * @param priorityFee_EVVM Priority fee for the EVVM transaction
     * @param nonce_EVVM Nonce for the EVVM contract transaction
     * @param priorityFlag_EVVM Priority flag for EVVM transaction
     * @param signature_EVVM Signature for the EVVM contract transaction
     */
    function stakingUserProcess(
        address user,
        uint256 amountOfStaking,
        bool isStaking,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) internal {
        stakingBaseProcess(
            user,
            user,
            isStaking,
            amountOfStaking,
            priorityFee_EVVM,
            nonce_EVVM,
            priorityFlag_EVVM,
            signature_EVVM
        );
    }

    /**
     * @notice Core staking logic that handles both service and user staking operations
     * @dev Processes payments, updates history, handles time locks, and manages EVVM integration
     * @param userAccount Address of the user paying for the transaction
     * @param stakingAccount Address that will receive the stake/unstake (can be same as userAccount)
     * @param isStaking True for staking (requires payment), false for unstaking (provides refund)
     * @param amountOfStaking Amount of staking tokens to stake/unstake
     * @param priorityFee_EVVM Priority fee for EVVM transaction
     * @param nonce_EVVM Nonce for EVVM contract transaction
     * @param priorityFlag_EVVM True for async EVVM transaction, false for sync
     * @param signature_EVVM Signature for EVVM contract transaction
     */
    function stakingBaseProcess(
        address userAccount,
        address stakingAccount,
        bool isStaking,
        uint256 amountOfStaking,
        uint256 priorityFee_EVVM,
        uint256 nonce_EVVM,
        bool priorityFlag_EVVM,
        bytes memory signature_EVVM
    ) internal {
        uint256 auxSMsteBalance;

        if (isStaking) {
            if (
                getTimeToUserUnlockStakingTime(stakingAccount) > block.timestamp
            ) revert ErrorsLib.UserMustWaitToStakeAgain();

            makePay(
                userAccount,
                (PRICE_OF_STAKING * amountOfStaking),
                priorityFee_EVVM,
                priorityFlag_EVVM,
                nonce_EVVM,
                signature_EVVM
            );

            Evvm(EVVM_ADDRESS).pointStaker(stakingAccount, 0x01);

            auxSMsteBalance = userHistory[stakingAccount].length == 0
                ? amountOfStaking
                : userHistory[stakingAccount][
                    userHistory[stakingAccount].length - 1
                ].totalStaked + amountOfStaking;
        } else {
            if (amountOfStaking == getUserAmountStaked(stakingAccount)) {
                if (
                    getTimeToUserUnlockFullUnstakingTime(stakingAccount) >
                    block.timestamp
                ) revert ErrorsLib.UserMustWaitToFullUnstake();

                Evvm(EVVM_ADDRESS).pointStaker(stakingAccount, 0x00);
            }

            // Only for user unstaking, not service
            if (userAccount == stakingAccount && priorityFee_EVVM != 0) {
                makePay(
                    userAccount,
                    priorityFee_EVVM,
                    0,
                    priorityFlag_EVVM,
                    nonce_EVVM,
                    signature_EVVM
                );
            }

            auxSMsteBalance =
                userHistory[stakingAccount][
                    userHistory[stakingAccount].length - 1
                ].totalStaked -
                amountOfStaking;

            makeCaPay(
                PRINCIPAL_TOKEN_ADDRESS,
                stakingAccount,
                (PRICE_OF_STAKING * amountOfStaking)
            );
        }

        userHistory[stakingAccount].push(
            HistoryMetadata({
                transactionType: isStaking
                    ? bytes32(uint256(1))
                    : bytes32(uint256(2)),
                amount: amountOfStaking,
                timestamp: block.timestamp,
                totalStaked: auxSMsteBalance
            })
        );

        if (Evvm(EVVM_ADDRESS).isAddressStaker(msg.sender)) {
            makeCaPay(
                PRINCIPAL_TOKEN_ADDRESS,
                msg.sender,
                (Evvm(EVVM_ADDRESS).getRewardAmount() * 2) + priorityFee_EVVM
            );
        }
    }

    /**
     * @notice Allows users to claim their staking rewards (yield)
     * @dev Interacts with the Estimator contract to calculate and distribute rewards
     * @param user Address of the user claiming rewards
     * @return epochAnswer Epoch identifier for the reward calculation
     * @return tokenToBeRewarded Address of the token being rewarded
     * @return amountTotalToBeRewarded Total amount of rewards to be distributed
     * @return idToOverwriteUserHistory Index in user history to update with reward info
     * @return timestampToBeOverwritten Timestamp to record for the reward transaction
     */
    function gimmeYiel(
        address user
    )
        external
        returns (
            bytes32 epochAnswer,
            address tokenToBeRewarded,
            uint256 amountTotalToBeRewarded,
            uint256 idToOverwriteUserHistory,
            uint256 timestampToBeOverwritten
        )
    {
        if (userHistory[user].length > 0) {
            (
                epochAnswer,
                tokenToBeRewarded,
                amountTotalToBeRewarded,
                idToOverwriteUserHistory,
                timestampToBeOverwritten
            ) = Estimator(estimator.actual).makeEstimation(user);

            if (amountTotalToBeRewarded > 0) {
                makeCaPay(tokenToBeRewarded, user, amountTotalToBeRewarded);

                userHistory[user][idToOverwriteUserHistory]
                    .transactionType = epochAnswer;
                userHistory[user][idToOverwriteUserHistory]
                    .amount = amountTotalToBeRewarded;
                userHistory[user][idToOverwriteUserHistory]
                    .timestamp = timestampToBeOverwritten;

                if (Evvm(EVVM_ADDRESS).isAddressStaker(msg.sender)) {
                    makeCaPay(
                        PRINCIPAL_TOKEN_ADDRESS,
                        msg.sender,
                        (Evvm(EVVM_ADDRESS).getRewardAmount() * 1)
                    );
                }
            }
        }
    }

    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    // Tools for Evvm Integration
    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /**
     * @notice Internal function to handle payments through the EVVM contract
     * @dev Supports both synchronous and asynchronous payment modes
     * @param user Address of the user making the payment
     * @param amount Amount to be paid in Principal Tokens
     * @param priorityFee Additional priority fee for the transaction
     * @param priorityFlag True for async payment, false for sync payment
     * @param nonce Nonce for the EVVM transaction
     * @param signature Signature authorizing the payment
     */
    function makePay(
        address user,
        uint256 amount,
        uint256 priorityFee,
        bool priorityFlag,
        uint256 nonce,
        bytes memory signature
    ) internal {
        Evvm(EVVM_ADDRESS).pay(
            user,
            address(this),
            "",
            PRINCIPAL_TOKEN_ADDRESS,
            amount,
            priorityFee,
            nonce,
            priorityFlag,
            address(this),
            signature
        );
    }

    /**
     * @notice Internal function to handle token distributions through EVVM contract
     * @dev Used for unstaking refunds and reward distributions
     * @param tokenAddress Address of the token to be distributed
     * @param user Address of the recipient
     * @param amount Amount of tokens to distribute
     */
    function makeCaPay(
        address tokenAddress,
        address user,
        uint256 amount
    ) internal {
        Evvm(EVVM_ADDRESS).caPay(user, tokenAddress, amount);
    }

    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    // Administrative Functions with Time-Delayed Governance
    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /**
     * @notice Adds a single address to the presale staker list
     * @dev Only admin can call this function, limited to 800 presale stakers total
     * @param _staker Address to be added to the presale staker list
     */
    function addPresaleStaker(address _staker) external onlyOwner {
        if (presaleStakerCount > LIMIT_PRESALE_STAKER) {
            revert();
        }
        userPresaleStaker[_staker].isAllow = true;
        presaleStakerCount++;
    }

    /**
     * @notice Adds multiple addresses to the presale staker list in batch
     * @dev Only admin can call this function, limited to 800 presale stakers total
     * @param _stakers Array of addresses to be added to the presale staker list
     */
    function addPresaleStakers(address[] calldata _stakers) external onlyOwner {
        for (uint256 i = 0; i < _stakers.length; i++) {
            if (presaleStakerCount > LIMIT_PRESALE_STAKER) {
                revert();
            }
            userPresaleStaker[_stakers[i]].isAllow = true;
            presaleStakerCount++;
        }
    }

    /**
     * @notice Proposes a new admin address with 1-day time delay
     * @dev Part of the time-delayed governance system for admin changes
     * @param _newAdmin Address of the proposed new admin
     */
    function proposeAdmin(address _newAdmin) external onlyOwner {
        admin.proposal = _newAdmin;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    /**
     * @notice Rejects the current admin proposal
     * @dev Only current admin can reject the pending proposal
     */
    function rejectProposalAdmin() external onlyOwner {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice Accepts the admin proposal and becomes the new admin
     * @dev Can only be called by the proposed admin after the time delay has passed
     */
    function acceptNewAdmin() external {
        if (
            msg.sender != admin.proposal || admin.timeToAccept > block.timestamp
        ) {
            revert();
        }
        admin.actual = admin.proposal;
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    function proposeGoldenFisher(address _goldenFisher) external onlyOwner {
        goldenFisher.proposal = _goldenFisher;
        goldenFisher.timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposalGoldenFisher() external onlyOwner {
        goldenFisher.proposal = address(0);
        goldenFisher.timeToAccept = 0;
    }

    function acceptNewGoldenFisher() external onlyOwner {
        if (goldenFisher.timeToAccept > block.timestamp) {
            revert();
        }
        goldenFisher.actual = goldenFisher.proposal;
        goldenFisher.proposal = address(0);
        goldenFisher.timeToAccept = 0;
    }

    function proposeSetSecondsToUnlockStaking(
        uint256 _secondsToUnlockStaking
    ) external onlyOwner {
        secondsToUnlockStaking.proposal = _secondsToUnlockStaking;
        secondsToUnlockStaking.timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposalSetSecondsToUnlockStaking() external onlyOwner {
        secondsToUnlockStaking.proposal = 0;
        secondsToUnlockStaking.timeToAccept = 0;
    }

    function acceptSetSecondsToUnlockStaking() external onlyOwner {
        if (secondsToUnlockStaking.timeToAccept > block.timestamp) {
            revert();
        }
        secondsToUnlockStaking.actual = secondsToUnlockStaking.proposal;
        secondsToUnlockStaking.proposal = 0;
        secondsToUnlockStaking.timeToAccept = 0;
    }

    function prepareSetSecondsToUnllockFullUnstaking(
        uint256 _secondsToUnllockFullUnstaking
    ) external onlyOwner {
        secondsToUnllockFullUnstaking.proposal = _secondsToUnllockFullUnstaking;
        secondsToUnllockFullUnstaking.timeToAccept = block.timestamp + 1 days;
    }

    function cancelSetSecondsToUnllockFullUnstaking() external onlyOwner {
        secondsToUnllockFullUnstaking.proposal = 0;
        secondsToUnllockFullUnstaking.timeToAccept = 0;
    }

    function confirmSetSecondsToUnllockFullUnstaking() external onlyOwner {
        if (secondsToUnllockFullUnstaking.timeToAccept > block.timestamp) {
            revert();
        }
        secondsToUnllockFullUnstaking.actual = secondsToUnllockFullUnstaking
            .proposal;
        secondsToUnllockFullUnstaking.proposal = 0;
        secondsToUnllockFullUnstaking.timeToAccept = 0;
    }

    function prepareChangeAllowPublicStaking() external onlyOwner {
        allowPublicStaking.timeToAccept = block.timestamp + 1 days;
    }

    function cancelChangeAllowPublicStaking() external onlyOwner {
        allowPublicStaking.timeToAccept = 0;
    }

    function confirmChangeAllowPublicStaking() external onlyOwner {
        if (allowPublicStaking.timeToAccept > block.timestamp) {
            revert();
        }
        allowPublicStaking = BoolTypeProposal({
            flag: !allowPublicStaking.flag,
            timeToAccept: 0
        });
    }

    function prepareChangeAllowPresaleStaking() external onlyOwner {
        allowPresaleStaking.timeToAccept = block.timestamp + 1 days;
    }

    function cancelChangeAllowPresaleStaking() external onlyOwner {
        allowPresaleStaking.timeToAccept = 0;
    }

    function confirmChangeAllowPresaleStaking() external onlyOwner {
        if (allowPresaleStaking.timeToAccept > block.timestamp) {
            revert();
        }
        allowPresaleStaking = BoolTypeProposal({
            flag: !allowPresaleStaking.flag,
            timeToAccept: 0
        });
    }

    function proposeEstimator(address _estimator) external onlyOwner {
        estimator.proposal = _estimator;
        estimator.timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposalEstimator() external onlyOwner {
        estimator.proposal = address(0);
        estimator.timeToAccept = 0;
    }

    function acceptNewEstimator() external onlyOwner {
        if (estimator.timeToAccept > block.timestamp) {
            revert();
        }
        estimator.actual = estimator.proposal;
        estimator.proposal = address(0);
        estimator.timeToAccept = 0;
    }

    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀
    // View Functions - Public Data Access
    //▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀▄▀

    /**
     * @notice Returns the complete staking history for an address
     * @dev Returns an array of all staking transactions and rewards for the user
     * @param _account Address to query the history for
     * @return Array of HistoryMetadata containing all transactions
     */
    function getAddressHistory(
        address _account
    ) public view returns (HistoryMetadata[] memory) {
        return userHistory[_account];
    }

    /**
     * @notice Returns the number of transactions in an address's staking history
     * @dev Useful for pagination or checking if an address has any staking history
     * @param _account Address to query the history size for
     * @return Number of transactions in the history
     */
    function getSizeOfAddressHistory(
        address _account
    ) public view returns (uint256) {
        return userHistory[_account].length;
    }

    /**
     * @notice Returns a specific transaction from an address's staking history
     * @dev Allows accessing individual transactions by index
     * @param _account Address to query the history for
     * @param _index Index of the transaction to retrieve (0-based)
     * @return HistoryMetadata of the transaction at the specified index
     */
    function getAddressHistoryByIndex(
        address _account,
        uint256 _index
    ) public view returns (HistoryMetadata memory) {
        return userHistory[_account][_index];
    }

    /**
     * @notice Returns the fixed price of one staking token in Principal Tokens
     * @dev Returns the constant price of 5083 Principal Tokens per staking
     * @return Price of one staking token in Principal Tokens (with 18 decimals)
     */
    function priceOfStaking() external pure returns (uint256) {
        return PRICE_OF_STAKING;
    }

    /**
     * @notice Calculates when a user can perform full unstaking (withdraw all tokens)
     * @dev Full unstaking requires waiting 21 days after the last time their balance reached 0
     * @param _account Address to check the unlock time for
     * @return Timestamp when full unstaking will be allowed
     */
    function getTimeToUserUnlockFullUnstakingTime(
        address _account
    ) public view returns (uint256) {
        for (uint256 i = userHistory[_account].length; i > 0; i--) {
            if (userHistory[_account][i - 1].totalStaked == 0) {
                return
                    userHistory[_account][i - 1].timestamp +
                    secondsToUnllockFullUnstaking.actual;
            }
        }

        return
            userHistory[_account][0].timestamp +
            secondsToUnllockFullUnstaking.actual;
    }

    /**
     * @notice Calculates when a user can stake again after unstaking
     * @dev Users must wait a configurable period after unstaking before they can stake again
     * @param _account Address to check the unlock time for
     * @return Timestamp when staking will be allowed again (0 if already allowed)
     */
    function getTimeToUserUnlockStakingTime(
        address _account
    ) public view returns (uint256) {
        uint256 lengthOfHistory = userHistory[_account].length;

        if (lengthOfHistory == 0) {
            return 0;
        }
        if (userHistory[_account][lengthOfHistory - 1].totalStaked == 0) {
            return
                userHistory[_account][lengthOfHistory - 1].timestamp +
                secondsToUnlockStaking.actual;
        } else {
            return 0;
        }
    }

    /**
     * @notice Returns the current time delay for full unstaking operations
     * @dev Full unstaking requires waiting this many seconds (default: 21 days)
     * @return Number of seconds required to wait for full unstaking
     */
    function getSecondsToUnlockFullUnstaking() external view returns (uint256) {
        return secondsToUnllockFullUnstaking.actual;
    }

    /**
     * @notice Returns the current time delay for regular staking operations
     * @dev Users must wait this many seconds after unstaking before they can stake again
     * @return Number of seconds required to wait between unstaking and staking
     */
    function getSecondsToUnlockStaking() external view returns (uint256) {
        return secondsToUnlockStaking.actual;
    }

    /**
     * @notice Returns the current amount of staking tokens staked by a user
     * @dev Returns the total staked amount from the user's most recent transaction
     * @param _account Address to check the staked amount for
     * @return Amount of staking tokens currently staked by the user
     */
    function getUserAmountStaked(
        address _account
    ) public view returns (uint256) {
        uint256 lengthOfHistory = userHistory[_account].length;

        if (lengthOfHistory == 0) {
            return 0;
        }

        return userHistory[_account][lengthOfHistory - 1].totalStaked;
    }

    /**
     * @notice Checks if a specific nonce has been used for staking by a user
     * @dev Prevents replay attacks by tracking used nonces
     * @param _account Address to check the nonce for
     * @param _nonce Nonce value to check
     * @return True if the nonce has been used, false otherwise
     */
    function checkIfStakeNonceUsed(
        address _account,
        uint256 _nonce
    ) public view returns (bool) {
        return stakingNonce[_account][_nonce];
    }

    /**
     * @notice Returns the current golden fisher address
     * @dev The golden fisher has special staking privileges
     * @return Address of the current golden fisher
     */
    function getGoldenFisher() external view returns (address) {
        return goldenFisher.actual;
    }

    /**
     * @notice Returns the proposed new golden fisher address (if any)
     * @dev Shows pending golden fisher changes in the governance system
     * @return Address of the proposed golden fisher (zero address if none)
     */
    function getGoldenFisherProposal() external view returns (address) {
        return goldenFisher.proposal;
    }

    /**
     * @notice Returns presale staker information for a given address
     * @dev Shows if an address is allowed for presale and how many tokens they've staked
     * @param _account Address to check presale status for
     * @return isAllow True if the address is allowed for presale staking
     * @return stakingAmount Number of staking tokens currently staked in presale (max 2)
     */
    function getPresaleStaker(
        address _account
    ) external view returns (bool, uint256) {
        return (
            userPresaleStaker[_account].isAllow,
            userPresaleStaker[_account].stakingAmount
        );
    }

    /**
     * @notice Returns the current estimator contract address
     * @dev The estimator calculates staking rewards and yields
     * @return Address of the current estimator contract
     */
    function getEstimatorAddress() external view returns (address) {
        return estimator.actual;
    }

    /**
     * @notice Returns the proposed new estimator contract address (if any)
     * @dev Shows pending estimator changes in the governance system
     * @return Address of the proposed estimator contract (zero address if none)
     */
    function getEstimatorProposal() external view returns (address) {
        return estimator.proposal;
    }

    /**
     * @notice Returns the current number of registered presale stakers
     * @dev Maximum allowed is 800 presale stakers
     * @return Current count of presale stakers
     */
    function getPresaleStakerCount() external view returns (uint256) {
        return presaleStakerCount;
    }

    /**
     * @notice Returns the complete public staking configuration and status
     * @dev Includes current flag state and any pending changes with timestamps
     * @return BoolTypeProposal struct containing flag and timeToAccept
     */
    function getAllDataOfAllowPublicStaking()
        external
        view
        returns (BoolTypeProposal memory)
    {
        return allowPublicStaking;
    }

    /**
     * @notice Returns the complete presale staking configuration and status
     * @dev Includes current flag state and any pending changes with timestamps
     * @return BoolTypeProposal struct containing flag and timeToAccept
     */
    function getAllowPresaleStaking()
        external
        view
        returns (BoolTypeProposal memory)
    {
        return allowPresaleStaking;
    }

    /**
     * @notice Returns the address of the EVVM core contract
     * @dev The EVVM contract handles payments and staker registration
     * @return Address of the EVVM core contract
     */
    function getEvvmAddress() external view returns (address) {
        return EVVM_ADDRESS;
    }

    /**
     * @notice Returns the address representing the Principal Token
     * @dev This is a constant address used to represent the principal token
     * @return Address representing the Principal Token (0x...0001)
     */
    function getMateAddress() external pure returns (address) {
        return PRINCIPAL_TOKEN_ADDRESS;
    }

    /**
     * @notice Returns the current admin/owner address
     * @dev The admin has full control over contract parameters and governance
     * @return Address of the current contract admin
     */
    function getOwner() external view returns (address) {
        return admin.actual;
    }
}
