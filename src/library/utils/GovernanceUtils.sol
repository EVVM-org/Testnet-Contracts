// SPDX-License-Identifier: EVVM-NONCOMMERCIAL-1.0
// Full license terms available at: https://www.evvm.info/docs/EVVMNoncommercialLicense

pragma solidity ^0.8.0;

library ProposalStructs {
    /**
     * @dev Struct for managing address change proposals with time delay
     * @param current Currently active address
     * @param proposal Proposed new address waiting for approval
     * @param timeToAccept Timestamp when the proposal can be accepted
     */
    struct AddressTypeProposal {
        address current;
        address proposal;
        uint256 timeToAccept;
    }

    /**
     * @dev Struct for managing uint256 value proposals with time delay
     * @param current Currently active value
     * @param proposal Proposed new value waiting for approval
     * @param timeToAccept Timestamp when the proposal can be accepted
     */
    struct UintTypeProposal {
        uint256 current;
        uint256 proposal;
        uint256 timeToAccept;
    }

    /**
     * @dev Struct for managing boolean flag changes with time delay
     * @param flag Current boolean state
     * @param timeToAcceptChange Timestamp when the flag change can be executed
     */
    struct BoolTypeProposal {
        bool flag;
        uint256 timeToAcceptChange;
    }
}

/**
 * @title AdminControlled
 * @notice Base contract for admin-controlled contracts with time-delayed governance
 */
abstract contract AdminControlled {
    ProposalStructs.AddressTypeProposal public admin;

    event AdminProposed(address indexed newAdmin, uint256 timeToAccept);
    event AdminAccepted(address indexed newAdmin);

    error SenderIsNotAdmin();
    error ProposalNotReady();

    modifier onlyAdmin() {
        if (msg.sender != admin.current) revert SenderIsNotAdmin();
        _;
    }

    /**
     * @notice Proposes a new admin with time delay
     * @param newAdmin Address of proposed admin
     * @param delay Time delay before proposal can be accepted
     */
    function proposeAdmin(address newAdmin, uint256 delay) external onlyAdmin {
        admin.proposal = newAdmin;
        admin.timeToAccept = block.timestamp + delay;
        emit AdminProposed(newAdmin, admin.timeToAccept);
    }

    /**
     * @notice Accepts the admin proposal after time delay
     */
    function acceptAdminProposal() external onlyAdmin {
        if (block.timestamp < admin.timeToAccept) revert ProposalNotReady();
        admin.current = admin.proposal;
        admin.proposal = address(0);
        admin.timeToAccept = 0;
        emit AdminAccepted(admin.current);
    }
}
