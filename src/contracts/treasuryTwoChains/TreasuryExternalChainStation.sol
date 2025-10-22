// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ErrorsLib} from "@EVVM/testnet-contracts/contracts/treasuryTwoChains/lib/ErrorsLib.sol";
import {ExternalChainStationStructs} from "@EVVM/testnet-contracts/contracts/treasuryTwoChains/lib/ExternalChainStationStructs.sol";

import {SafeTransferLib} from "@solady/utils/SafeTransferLib.sol";

import {SignatureUtils} from "@EVVM/testnet-contracts/contracts/treasuryTwoChains/lib/SignatureUtils.sol";

import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

import {OApp, Origin, MessagingFee} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {OptionsBuilder} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AxelarExecutable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import {IAxelarGasService} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IInterchainGasEstimation} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IInterchainGasEstimation.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract TreasuryExternalChainStation is
    ExternalChainStationStructs,
    OApp,
    OAppOptionsType3,
    AxelarExecutable
{
    AddressTypeProposal admin;

    AddressTypeProposal fisherExecutor;

    HyperlaneConfig hyperlane;

    LayerZeroConfig layerZero;

    AxelarConfig axelar;

    uint256 immutable EVVM_ID;

    mapping(address => uint256) nextFisherExecutionNonce;

    bytes _options =
        OptionsBuilder.addExecutorLzReceiveOption(
            OptionsBuilder.newOptions(),
            50000,
            0
        );

    event FisherBridgeSend(
        address indexed from,
        address indexed addressToReceive,
        address indexed tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        uint256 nonce
    );

    modifier onlyAdmin() {
        if (msg.sender != admin.current) {
            revert();
        }
        _;
    }

    modifier onlyFisherExecutor() {
        if (msg.sender != fisherExecutor.current) {
            revert();
        }
        _;
    }

    constructor(
        address _admin,
        CrosschainConfig memory _crosschainConfig,
        uint256 _evvmId
    )
        OApp(_crosschainConfig.endpointAddress, _admin)
        Ownable(_admin)
        AxelarExecutable(_crosschainConfig.gatewayAddress)
    {
        admin = AddressTypeProposal({
            current: _admin,
            proposal: address(0),
            timeToAccept: 0
        });
        hyperlane = HyperlaneConfig({
            hostChainStationDomainId: _crosschainConfig
                .hostChainStationDomainId,
            hostChainStationAddress: "",
            mailboxAddress: _crosschainConfig.mailboxAddress
        });
        layerZero = LayerZeroConfig({
            hostChainStationEid: _crosschainConfig.hostChainStationEid,
            hostChainStationAddress: "",
            endpointAddress: _crosschainConfig.endpointAddress
        });
        axelar = AxelarConfig({
            hostChainStationChainName: _crosschainConfig
                .hostChainStationChainName,
            hostChainStationAddress: "",
            gasServiceAddress: _crosschainConfig.gasServiceAddress,
            gatewayAddress: _crosschainConfig.gatewayAddress
        });
        EVVM_ID = _evvmId;
    }

    function setHostChainAddress(
        address hostChainStationAddress,
        string memory hostChainStationAddressString
    ) external onlyAdmin {
        hyperlane.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainStationAddress))
        );
        layerZero.hostChainStationAddress = bytes32(
            uint256(uint160(hostChainStationAddress))
        );
        axelar.hostChainStationAddress = hostChainStationAddressString;
        _setPeer(
            layerZero.hostChainStationEid,
            layerZero.hostChainStationAddress
        );
    }

    /**
     * @notice Withdraw ETH or ERC20 tokens
     * @param token Token address (address(0) for ETH)
     * @param amount Amount to withdraw
     */
    function depositERC20(
        address toAddress,
        address token,
        uint256 amount,
        bytes1 protocolToExecute
    ) external payable {
        bytes memory payload = encodePayload(token, toAddress, amount);
        verifyAndDepositERC20(token, amount);
        if (protocolToExecute == 0x01) {
            // 0x01 = Hyperlane
            uint256 quote = getQuoteHyperlane(toAddress, token, amount);
            /*messageId = */ IMailbox(hyperlane.mailboxAddress).dispatch{
                value: quote
            }(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                payload
            );
        } else if (protocolToExecute == 0x02) {
            // 0x02 = LayerZero
            uint256 fee = quoteLayerZero(toAddress, token, amount);
            _lzSend(
                layerZero.hostChainStationEid,
                payload,
                _options,
                MessagingFee(fee, 0),
                msg.sender // Refund any excess fees to the sender.
            );
        } else if (protocolToExecute == 0x03) {
            // 0x03 = Axelar
            IAxelarGasService(axelar.gasServiceAddress)
                .payNativeGasForContractCall{value: msg.value}(
                address(this),
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload,
                msg.sender
            );
            gateway().callContract(
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload
            );
        } else {
            revert();
        }
    }

    function depositCoin(
        address toAddress,
        uint256 amount,
        bytes1 protocolToExecute
    ) external payable {
        if (msg.value < amount) revert ErrorsLib.InsufficientBalance();

        bytes memory payload = encodePayload(address(0), toAddress, amount);

        if (protocolToExecute == 0x01) {
            // 0x01 = Hyperlane
            uint256 quote = getQuoteHyperlane(toAddress, address(0), amount);
            if (msg.value < quote + amount)
                revert ErrorsLib.InsufficientBalance();
            /*messageId = */ IMailbox(hyperlane.mailboxAddress).dispatch{
                value: quote
            }(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                payload
            );
        } else if (protocolToExecute == 0x02) {
            // 0x02 = LayerZero
            uint256 fee = quoteLayerZero(toAddress, address(0), amount);
            if (msg.value < fee + amount)
                revert ErrorsLib.InsufficientBalance();
            _lzSend(
                layerZero.hostChainStationEid,
                payload,
                _options,
                MessagingFee(fee, 0),
                msg.sender // Refund any excess fees to the sender.
            );
        } else if (protocolToExecute == 0x03) {
            // 0x03 = Axelar
            IAxelarGasService(axelar.gasServiceAddress)
                .payNativeGasForContractCall{value: msg.value - amount}(
                address(this),
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload,
                msg.sender
            );
            gateway().callContract(
                axelar.hostChainStationChainName,
                axelar.hostChainStationAddress,
                payload
            );
        } else {
            revert();
        }
    }

    function fisherBridgeReceive(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external onlyFisherExecutor {
        if (
            !SignatureUtils.verifyMessageSignedForFisherBridge(
                EVVM_ID,
                from,
                addressToReceive,
                nextFisherExecutionNonce[from],
                tokenAddress,
                priorityFee,
                amount,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        nextFisherExecutionNonce[from]++;
    }

    function fisherBridgeSendERC20(
        address from,
        address addressToReceive,
        address tokenAddress,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external onlyFisherExecutor {
        if (
            !SignatureUtils.verifyMessageSignedForFisherBridge(
                EVVM_ID,
                from,
                addressToReceive,
                nextFisherExecutionNonce[from],
                tokenAddress,
                priorityFee,
                amount,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        verifyAndDepositERC20(tokenAddress, amount);

        nextFisherExecutionNonce[from]++;

        emit FisherBridgeSend(
            from,
            addressToReceive,
            tokenAddress,
            priorityFee,
            amount,
            nextFisherExecutionNonce[from] - 1
        );
    }

    function fisherBridgeSendCoin(
        address from,
        address addressToReceive,
        uint256 priorityFee,
        uint256 amount,
        bytes memory signature
    ) external payable onlyFisherExecutor {
        if (
            !SignatureUtils.verifyMessageSignedForFisherBridge(
                EVVM_ID,
                from,
                addressToReceive,
                nextFisherExecutionNonce[from],
                address(0),
                priorityFee,
                amount,
                signature
            )
        ) revert ErrorsLib.InvalidSignature();

        if (msg.value != amount + priorityFee)
            revert ErrorsLib.InsufficientBalance();

        nextFisherExecutionNonce[from]++;

        emit FisherBridgeSend(
            from,
            addressToReceive,
            address(0),
            priorityFee,
            amount,
            nextFisherExecutionNonce[from] - 1
        );
    }

    // Hyperlane Specific Functions //
    function getQuoteHyperlane(
        address toAddress,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        return
            IMailbox(hyperlane.mailboxAddress).quoteDispatch(
                hyperlane.hostChainStationDomainId,
                hyperlane.hostChainStationAddress,
                encodePayload(token, toAddress, amount)
            );
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual {
        if (msg.sender != hyperlane.mailboxAddress)
            revert ErrorsLib.MailboxNotAuthorized();

        if (_sender != hyperlane.hostChainStationAddress)
            revert ErrorsLib.SenderNotAuthorized();

        if (_origin != hyperlane.hostChainStationDomainId)
            revert ErrorsLib.ChainIdNotAuthorized();

        decodeAndGive(_data);
    }

    // LayerZero Specific Functions //

    function quoteLayerZero(
        address toAddress,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        MessagingFee memory fee = _quote(
            layerZero.hostChainStationEid,
            encodePayload(token, toAddress, amount),
            _options,
            false
        );
        return fee.nativeFee;
    }

    function _lzReceive(
        Origin calldata _origin,
        bytes32 /*_guid*/,
        bytes calldata message,
        address /*executor*/, // Executor address as specified by the OApp.
        bytes calldata /*_extraData*/ // Any extra data or options to trigger on receipt.
    ) internal override {
        // Decode the payload to get the message
        if (_origin.srcEid != layerZero.hostChainStationEid)
            revert ErrorsLib.ChainIdNotAuthorized();

        if (_origin.sender != layerZero.hostChainStationAddress)
            revert ErrorsLib.SenderNotAuthorized();

        decodeAndGive(message);
    }

    // Axelar Specific Functions //

    function _execute(
        bytes32 /*commandId*/,
        string calldata _sourceChain,
        string calldata _sourceAddress,
        bytes calldata _payload
    ) internal override {
        if (!Strings.equal(_sourceChain, axelar.hostChainStationChainName))
            revert ErrorsLib.ChainIdNotAuthorized();

        if (!Strings.equal(_sourceAddress, axelar.hostChainStationAddress))
            revert ErrorsLib.SenderNotAuthorized();

        decodeAndGive(_payload);
    }

    /**
     * @notice Proposes a new admin address with 1-day time delay
     * @dev Part of the time-delayed governance system for admin changes
     * @param _newOwner Address of the proposed new admin
     */
    function proposeAdmin(address _newOwner) external onlyAdmin {
        if (_newOwner == address(0) || _newOwner == admin.current) revert();

        admin.proposal = _newOwner;
        admin.timeToAccept = block.timestamp + 1 days;
    }

    /**
     * @notice Cancels a pending admin change proposal
     * @dev Allows current admin to reject proposed admin changes
     */
    function rejectProposalAdmin() external onlyAdmin {
        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    /**
     * @notice Accepts a pending admin proposal and becomes the new admin
     * @dev Can only be called by the proposed admin after the time delay
     */
    function acceptAdmin() external {
        if (block.timestamp < admin.timeToAccept) revert();

        if (msg.sender != admin.proposal) revert();

        admin.current = admin.proposal;

        admin.proposal = address(0);
        admin.timeToAccept = 0;
    }

    function proposeFisherExecutor(
        address _newFisherExecutor
    ) external onlyAdmin {
        if (
            _newFisherExecutor == address(0) ||
            _newFisherExecutor == fisherExecutor.current
        ) revert();

        fisherExecutor.proposal = _newFisherExecutor;
        fisherExecutor.timeToAccept = block.timestamp + 1 days;
    }

    function rejectProposalFisherExecutor() external onlyAdmin {
        fisherExecutor.proposal = address(0);
        fisherExecutor.timeToAccept = 0;
    }

    function acceptFisherExecutor() external {
        if (block.timestamp < fisherExecutor.timeToAccept) revert();

        if (msg.sender != fisherExecutor.proposal) revert();

        fisherExecutor.current = fisherExecutor.proposal;

        fisherExecutor.proposal = address(0);
        fisherExecutor.timeToAccept = 0;
    }

    // Getter functions //
    function getAdmin() external view returns (AddressTypeProposal memory) {
        return admin;
    }

    function getFisherExecutor()
        external
        view
        returns (AddressTypeProposal memory)
    {
        return fisherExecutor;
    }

    function getNextFisherExecutionNonce(
        address user
    ) external view returns (uint256) {
        return nextFisherExecutionNonce[user];
    }

    function getHyperlaneConfig()
        external
        view
        returns (HyperlaneConfig memory)
    {
        return hyperlane;
    }

    function getLayerZeroConfig()
        external
        view
        returns (LayerZeroConfig memory)
    {
        return layerZero;
    }

    function getAxelarConfig() external view returns (AxelarConfig memory) {
        return axelar;
    }

    function getOptions() external view returns (bytes memory) {
        return _options;
    }

    // Internal Functions //

    function decodeAndGive(bytes memory payload) internal {
        (address token, address toAddress, uint256 amount) = decodePayload(
            payload
        );
        if (token == address(0))
            SafeTransferLib.safeTransferETH(msg.sender, amount);
        else IERC20(token).transfer(toAddress, amount);
    }

    function verifyAndDepositERC20(address token, uint256 amount) internal {
        if (token == address(0)) revert();
        if (IERC20(token).allowance(msg.sender, address(this)) < amount)
            revert ErrorsLib.InsufficientBalance();

        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function encodePayload(
        address token,
        address toAddress,
        uint256 amount
    ) internal pure returns (bytes memory payload) {
        payload = abi.encode(token, toAddress, amount);
    }

    function decodePayload(
        bytes memory payload
    ) internal pure returns (address token, address toAddress, uint256 amount) {
        (token, toAddress, amount) = abi.decode(
            payload,
            (address, address, uint256)
        );
    }
}
