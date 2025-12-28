// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

/**
 * @title EvvmStorage
 * @author jistro.eth
 * @dev Storage layout contract for EVVM proxy pattern implementation.
 *      This contract inherits all structures from EvvmStructs and
 *      defines the storage layout that will be used by the proxy pattern.
 *
 * @notice This contract should not be deployed directly, it's meant to be
 *         inherited by the implementation contracts to ensure they maintain
 *         the same storage layout.
 */

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {Staking} from "@evvm/testnet-contracts/contracts/staking/Staking.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {StakingServiceUtils} from "@evvm/testnet-contracts/library/utils/service/StakingServiceUtils.sol";
import {IStaking} from "@evvm/testnet-contracts/interfaces/IStaking.sol";
import {IEvvm} from "@evvm/testnet-contracts/interfaces/IEvvm.sol";

abstract contract Constants {
    bytes32 constant DEPOSIT_HISTORY_SMATE_IDENTIFIER = bytes32(uint256(1));
    bytes32 constant WITHDRAW_HISTORY_SMATE_IDENTIFIER = bytes32(uint256(2));

    address constant MATE_TOKEN_ADDRESS =
        0x0000000000000000000000000000000000000001;

    address constant ETHER_ADDRESS = 0x0000000000000000000000000000000000000000;

    /*
        | ACCOUNT       |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  | 
        | ADMIN         |  X  |     |     |     |     |     |     |     |
        | Common users  |     |  X  |  X  |  X  |     |     |     |     |
        | Staker        |     |     |     |  X  |  X  |     |     |     |
        | Golden        |     |     |     |     |     |  X  |     |     |
        | Activator     |     |     |     |     |     |     |  X  |     |
        
        The 8th user is used as a WILDCARD
    */

    struct AccountData {
        address Address;
        uint256 PrivateKey;
    }

    AccountData ACCOUNT1 =
        AccountData({
            Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266,
            PrivateKey: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
        });

    AccountData ACCOUNT2 =
        AccountData({
            Address: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8,
            PrivateKey: 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
        });

    AccountData ACCOUNT3 =
        AccountData({
            Address: 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC,
            PrivateKey: 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
        });

    AccountData ACCOUNT4 =
        AccountData({
            Address: 0x90F79bf6EB2c4f870365E785982E1f101E93b906,
            PrivateKey: 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
        });

    AccountData ACCOUNT5 =
        AccountData({
            Address: 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65,
            PrivateKey: 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
        });

    AccountData ACCOUNT6 =
        AccountData({
            Address: 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc,
            PrivateKey: 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
        });

    AccountData ACCOUNT7 =
        AccountData({
            Address: 0x976EA74026E726554dB657fA54763abd0C3a0aa9,
            PrivateKey: 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
        });

    AccountData ACCOUNT8 =
        AccountData({
            Address: 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955,
            PrivateKey: 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
        });

    AccountData ADMIN =
        AccountData({
            Address: ACCOUNT1.Address,
            PrivateKey: ACCOUNT1.PrivateKey
        });

    AccountData COMMON_USER_NO_STAKER_1 =
        AccountData({
            Address: ACCOUNT2.Address,
            PrivateKey: ACCOUNT2.PrivateKey
        });

    AccountData COMMON_USER_NO_STAKER_2 =
        AccountData({
            Address: ACCOUNT3.Address,
            PrivateKey: ACCOUNT3.PrivateKey
        });

    AccountData COMMON_USER_STAKER =
        AccountData({
            Address: ACCOUNT4.Address,
            PrivateKey: ACCOUNT4.PrivateKey
        });

    // this should be apllied only on sMATE and estimator tests
    AccountData STAKER =
        AccountData({
            Address: ACCOUNT5.Address,
            PrivateKey: ACCOUNT5.PrivateKey
        });

    AccountData GOLDEN_STAKER =
        AccountData({
            Address: ACCOUNT6.Address,
            PrivateKey: ACCOUNT6.PrivateKey
        });

    AccountData ACTIVATOR =
        AccountData({
            Address: ACCOUNT7.Address,
            PrivateKey: ACCOUNT7.PrivateKey
        });

    AccountData WILDCARD_USER =
        AccountData({
            Address: ACCOUNT8.Address,
            PrivateKey: ACCOUNT8.PrivateKey
        });
}

contract MockContractToStake is StakingServiceUtils {
    constructor(address stakingAddress) StakingServiceUtils(stakingAddress) {}

    function stake(uint256 amountToStake) public {
        _makeStakeService(amountToStake);
    }

    function stakeJustInPartOne(uint256 amountToStake) public {
        staking.prepareServiceStaking(amountToStake);
    }

    function stakeJustInPartTwo(uint256 amountToStake) public {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            0x0000000000000000000000000000000000000001,
            staking.priceOfStaking() * amountToStake
        );
    }

    function stakeJustConfirm() public {
        staking.confirmServiceStaking();
    }

    function stakeWithTokenAddress(
        uint256 amountToStake,
        address tokenAddress
    ) public {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            tokenAddress,
            staking.priceOfStaking() * amountToStake
        );
        staking.confirmServiceStaking();
    }

    function stakeWithAmountDiscrepancy(
        uint256 amountToStakeDiscrepancy,
        uint256 amountToStake
    ) public {
        staking.prepareServiceStaking(amountToStake);
        IEvvm(staking.getEvvmAddress()).caPay(
            address(staking),
            0x0000000000000000000000000000000000000001,
            staking.priceOfStaking() * amountToStakeDiscrepancy
        );
        staking.confirmServiceStaking();
    }

    function unstake(uint256 amountToUnstake) public {
        _makeUnstakeService(amountToUnstake);
    }

    function getBackMate(address user) public {
        IEvvm(staking.getEvvmAddress()).caPay(
            user,
            0x0000000000000000000000000000000000000001,
            IEvvm(staking.getEvvmAddress()).getBalance(
                address(this),
                0x0000000000000000000000000000000000000001
            )
        );
    }
}

contract TestERC20 is ERC20 {

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }


    function name() public view override returns (string memory){
        return "TestToken";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view override returns (string memory){
        return "TTK";
    }

}

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract RegistryEvvmTestTwo is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    error InvalidUser();
    error InvalidInput();
    error AlreadyRegistered(uint256 chainId, address evvmAddress);
    error ChainIdNotRegistered();
    error EvvmIdAlreadyRegistered();

    /**
     * @notice Metadata structure for EVVM registration
     * @param chainId The chain ID where the EVVM is deployed
     * @param evvmAddress The contract address of the EVVM
     */
    struct Metadata {
        uint256 chainId;
        address evvmAddress;
    }

    /**
     * @notice Structure for managing time-delayed governance proposals
     * @param current The currently active address
     * @param proposal The proposed new address
     * @param timeToAccept Timestamp when the proposal can be accepted (current time + 7 days)
     */
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    AddressTypeProposal superUser;
    AddressTypeProposal upgradeProposal;

    mapping(uint256 evvmID => Metadata) private registry;
    mapping(uint256 chainId => bool answer) private isThisChainIdRegistered;
    mapping(uint256 chainId => mapping(address evvm => bool answer)) isThisAddressRegistered;

    uint256 constant MAX_WHITE_LISTED_EVMM_ID = 999;
    uint256 publicCounter;

    modifier isSuperUser() {
        if (msg.sender != superUser.current) revert InvalidUser();

        _;
    }

    /**
     * @notice Constructor that disables initializers for the implementation contract
     * @dev Prevents the implementation contract from being initialized directly
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the registry contract with initial superUser
     * @dev Sets up the contract with initial parameters and inheritance chain
     * @param initialSuperUser Address that will have superUser privileges
     */
    function initialize(address initialSuperUser) public initializer {
        publicCounter = 1000;
        superUser = AddressTypeProposal(initialSuperUser, address(0), 0);
        __Ownable_init(initialSuperUser);
        __UUPSUpgradeable_init();
    }

    /**
     * @notice Public registration function for EVVM instances
     * @dev Anyone can register an EVVM if the chain ID is whitelisted and the address isn't already registered
     * @param chainId The chain ID of the testnet where the EVVM is deployed
     * @param evvmAddress The contract address of the EVVM instance
     * @return The assigned EVVM ID (auto-incremented from 1000 onwards)
     *
     * Requirements:
     * - chainId must be non-zero and whitelisted
     * - evvmAddress must be non-zero and not already registered for this chainId
     *
     * @custom:security Only works with whitelisted testnet chain IDs to prevent mainnet registration
     */
    function registerEvvm(
        uint256 chainId,
        address evvmAddress
    ) external returns (uint256) {
        if (chainId == 0 || evvmAddress == address(0)) revert InvalidInput();

        if (isThisAddressRegistered[chainId][evvmAddress])
            revert AlreadyRegistered(chainId, evvmAddress);

        if (!isThisChainIdRegistered[chainId]) revert ChainIdNotRegistered();

        uint256 evvmID = publicCounter;
        registry[evvmID] = Metadata(chainId, evvmAddress);
        isThisAddressRegistered[chainId][evvmAddress] = true;
        publicCounter++;

        return evvmID;
    }

    /**
     * @notice SuperUser registration function for whitelisted EVVM IDs
     * @dev Only superUser can register EVVMs with specific IDs in the reserved range (1-999)
     * @param evvmID The specific ID to assign (must be between 1-999)
     * @param chainId The chain ID of the testnet where the EVVM is deployed
     * @param evvmAddress The contract address of the EVVM instance
     * @return The assigned EVVM ID (same as input evvmID)
     *
     * Requirements:
     * - Only callable by superUser
     * - evvmID must be between 1 and 999 (MAX_WHITE_LISTED_EVMM_ID)
     * - chainId must be non-zero and whitelisted
     * - evvmAddress must be non-zero and not already registered for this chainId
     * - The specified evvmID must not already be registered
     *
     * @custom:access-control Restricted to superUser only
     * @custom:security Reserved IDs (1-999) for official EVVM deployments
     */
    function sudoRegisterEvvm(
        uint256 evvmID,
        uint256 chainId,
        address evvmAddress
    ) external isSuperUser returns (uint256) {
        if (
            evvmID < 1 ||
            evvmID > MAX_WHITE_LISTED_EVMM_ID ||
            chainId == 0 ||
            evvmAddress == address(0)
        ) revert InvalidInput();

        if (isThisAddressRegistered[chainId][evvmAddress])
            revert AlreadyRegistered(chainId, evvmAddress);

        if (
            registry[evvmID].chainId != 0 &&
            registry[evvmID].evvmAddress != address(0)
        ) revert EvvmIdAlreadyRegistered();

        if (!isThisChainIdRegistered[chainId]) revert ChainIdNotRegistered();

        registry[evvmID] = Metadata(chainId, evvmAddress);
        isThisAddressRegistered[chainId][evvmAddress] = true;

        return evvmID;
    }

    /**
     * @notice Registers multiple chain IDs to the whitelist
     * @dev Only superUser can add chain IDs to prevent mainnet registration
     * @param chainIds Array of chain IDs to whitelist for EVVM registration
     *
     * Requirements:
     * - Only callable by superUser
     * - All chain IDs must be non-zero
     *
     * @custom:access-control Restricted to superUser only
     * @custom:security Prevents registration on non-testnet chains by controlling whitelist
     */
    function registerChainId(uint256[] memory chainIds) external isSuperUser {
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] == 0) revert InvalidInput();
            isThisChainIdRegistered[chainIds[i]] = true;
        }
    }

    /**
     * @notice Proposes a new superUser address with 7-day time delay
     * @dev Part of the time-delayed governance system for superUser changes
     * @param _newSuperUser Address of the proposed new superUser
     */
    function proposeSuperUser(address _newSuperUser) external isSuperUser {
        if (_newSuperUser == address(0) || _newSuperUser == superUser.current) {
            revert();
        }

        superUser.proposal = _newSuperUser;
        superUser.timeToAccept = block.timestamp + 7 days;
    }

    /**
     * @notice Cancels a pending superUser change proposal
     * @dev Allows current superUser to reject proposed superUser changes
     */
    function rejectProposalSuperUser() external isSuperUser {
        superUser.proposal = address(0);
        superUser.timeToAccept = 0;
    }

    /**
     * @notice Accepts a pending superUser proposal and becomes the new superUser
     * @dev Can only be called by the proposed superUser after the time delay
     */
    function acceptSuperUser() external {
        if (block.timestamp < superUser.timeToAccept) {
            revert();
        }
        if (msg.sender != superUser.proposal) {
            revert();
        }

        superUser.current = superUser.proposal;

        superUser.proposal = address(0);
        superUser.timeToAccept = 0;
        _transferOwnership(superUser.current);
    }

    /**
     * @notice Proposes a new implementation address for upgrade with 7-day time delay
     * @dev Part of the time-delayed governance system for contract upgrades
     * @param _newImplementation Address of the proposed new implementation
     */
    function proposeUpgrade(address _newImplementation) external isSuperUser {
        if (_newImplementation == address(0)) {
            revert InvalidInput();
        }

        upgradeProposal.proposal = _newImplementation;
        upgradeProposal.timeToAccept = block.timestamp + 7 days;
    }

    /**
     * @notice Cancels a pending upgrade proposal
     * @dev Allows current superUser to reject proposed upgrades
     */
    function rejectProposalUpgrade() external isSuperUser {
        upgradeProposal.proposal = address(0);
        upgradeProposal.timeToAccept = 0;
    }

    /**
     * @notice Accepts a pending upgrade proposal and executes the upgrade
     * @dev Can only be called by the superUser after the time delay
     */
    function acceptProposalUpgrade() external isSuperUser {
        if (block.timestamp < upgradeProposal.timeToAccept) {
            revert();
        }
        if (upgradeProposal.proposal == address(0)) {
            revert InvalidInput();
        }

        address newImplementation = upgradeProposal.proposal;

        // Reset the proposal before upgrade
        upgradeProposal.proposal = address(0);
        upgradeProposal.timeToAccept = 0;

        // Execute the upgrade
        upgradeToAndCall(newImplementation, "");
    }

    /**
     * @notice Retrieves metadata for a specific EVVM ID
     * @dev View function that returns chain ID and contract address for given EVVM ID
     * @param evvmID The EVVM ID to query
     * @return Metadata struct containing chainId and evvmAddress
     *
     * @custom:usage dApps can use this to verify they're interacting with the correct EVVM
     */
    function getEvvmIdMetadata(
        uint256 evvmID
    ) external view returns (Metadata memory) {
        return registry[evvmID];
    }

    /**
     * @notice Retrieves all active whitelisted EVVM IDs (1-999)
     * @dev View function that returns array of registered EVVM IDs in the reserved range
     * @return Array of active EVVM IDs in the whitelisted range (1-999)
     *
     * @custom:usage Indexer function to discover all official EVVM deployments
     * @custom:gas-warning This function can be gas-intensive for large numbers of registrations
     */
    function getWhiteListedEvvmIdActive()
        external
        view
        returns (uint256[] memory)
    {
        uint256 count;
        for (uint256 i = 1; i <= MAX_WHITE_LISTED_EVMM_ID; i++) {
            if (
                registry[i].chainId != 0 &&
                registry[i].evvmAddress != address(0)
            ) {
                count++;
            }
        }

        uint256[] memory activeEvvmIds = new uint256[](count);
        uint256 index;

        for (uint256 i = 1; i <= MAX_WHITE_LISTED_EVMM_ID; i++) {
            if (
                registry[i].chainId != 0 &&
                registry[i].evvmAddress != address(0)
            ) {
                activeEvvmIds[index] = i;
                index++;
            }
        }

        return activeEvvmIds;
    }

    /**
     * @notice Retrieves all active public EVVM IDs (1000+)
     * @dev View function that returns array of registered EVVM IDs in the public range
     * @return Array of active EVVM IDs in the public range (1000+)
     *
     * @custom:usage Indexer function to discover all community EVVM deployments
     * @custom:gas-warning This function can be gas-intensive for large numbers of registrations
     */
    function getPublicEvvmIdActive() external view returns (uint256[] memory) {
        uint256 count = publicCounter - MAX_WHITE_LISTED_EVMM_ID - 1;

        uint256[] memory activeEvvmIds = new uint256[](count);
        uint256 index;

        for (uint256 i = MAX_WHITE_LISTED_EVMM_ID + 1; i < publicCounter; i++) {
            if (
                registry[i].chainId != 0 &&
                registry[i].evvmAddress != address(0)
            ) {
                activeEvvmIds[index] = i;
                index++;
            }
        }

        return activeEvvmIds;
    }

    /**
     * @notice Internal authorization function for upgrades
     * @dev Required by UUPSUpgradeable, but authorization is handled in acceptProposalUpgrade
     * @param newImplementation Address of the new implementation (unused in this context)
     *
     * @custom:security Authorization is handled through time-delayed governance in acceptProposalUpgrade
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override isSuperUser {
        // Authorization is now handled in acceptProposalUpgrade
        // This function is called internally by upgradeToAndCall
    }

    /**
     * @notice Retrieves complete superUser governance data
     * @dev Returns the full AddressTypeProposal struct with current, proposed, and timing information
     * @return AddressTypeProposal struct containing current superUser, proposed superUser, and acceptance timestamp
     *
     * @custom:usage For governance interfaces to display superUser change status
     */
    function getSuperUserData()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return superUser;
    }

    /**
     * @notice Retrieves the current superUser address
     * @dev Simple getter for the current superUser address
     * @return Address of the current superUser
     */
    function getSuperUser() external view returns (address) {
        return superUser.current;
    }

    /**
     * @notice Checks if a chain ID is whitelisted for registration
     * @dev View function to verify if registrations are allowed on a specific chain
     * @param chainId The chain ID to check
     * @return bool True if the chain ID is whitelisted, false otherwise
     *
     * @custom:usage dApps can use this to verify if a chain is supported before attempting registration
     */
    function isChainIdRegistered(uint256 chainId) external view returns (bool) {
        return isThisChainIdRegistered[chainId];
    }

    /**
     * @notice Checks if an EVVM address is already registered on a specific chain
     * @dev View function to prevent duplicate registrations
     * @param chainId The chain ID to check
     * @param evvmAddress The EVVM address to check
     * @return bool True if the address is already registered on this chain, false otherwise
     *
     * @custom:usage Prevents duplicate registrations and verifies existing registrations
     */
    function isAddressRegistered(
        uint256 chainId,
        address evvmAddress
    ) external view returns (bool) {
        return isThisAddressRegistered[chainId][evvmAddress];
    }

    /**
     * @notice Retrieves complete upgrade proposal governance data
     * @dev Returns the full AddressTypeProposal struct with current, proposed, and timing information for upgrades
     * @return AddressTypeProposal struct containing current implementation, proposed implementation, and acceptance timestamp
     *
     * @custom:usage For governance interfaces to display upgrade proposal status
     */
    function getUpgradeProposalData()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return upgradeProposal;
    }

    /**
     * @notice Returns the contract version
     * @dev Simple version identifier for tracking contract updates
     * @return uint256 Current version number of the contract
     *
     * @custom:usage For compatibility checks and version tracking
     */
    function getVersion() external pure returns (uint256) {
        return 2;
    }
}
