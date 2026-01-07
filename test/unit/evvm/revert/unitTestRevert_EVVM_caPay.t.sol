// SPDX-License-Identifier: MIT

/**
 ____ ____ ____ ____ _________ ____ ____ ____ ____ 
||U |||N |||I |||T |||       |||T |||E |||S |||T ||
||__|||__|||__|||__|||_______|||__|||__|||__|||__||
|/__\|/__\|/__\|/__\|/_______\|/__\|/__\|/__\|/__\|

 * @title unit test for EVVM function revert behavior
 * @notice some functions has evvm functions that are implemented
 *         and dosent need to be tested here
 */
import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "test/Constants.sol";
import "@evvm/testnet-contracts/library/Erc191TestBuilder.sol";

import {Evvm} from "@evvm/testnet-contracts/contracts/evvm/Evvm.sol";
import {
    ErrorsLib
} from "@evvm/testnet-contracts/contracts/evvm/lib/ErrorsLib.sol";

contract unitTestRevert_EVVM_caPay is Test, Constants {
    //function executeBeforeSetUp() internal override {}

    function _addBalance(
        address _ca,
        address _token,
        uint256 _amount
    ) private returns (uint256 amount) {
        evvm.addBalance(_ca, _token, _amount);
        return (_amount);
    }

    function test__unit_revert__caPay__NotAnCA() external {
        _addBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS, 0.1 ether);

        vm.startPrank(COMMON_USER_NO_STAKER_1.Address);

        vm.expectRevert(ErrorsLib.NotAnCA.selector);
        evvm.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, 0.001 ether);

        vm.stopPrank();

        assertEq(
            evvm.getBalance(COMMON_USER_NO_STAKER_1.Address, ETHER_ADDRESS),
            0.1 ether,
            "Amount should not be deducted because of revert"
        );
    }

    function test__unit_revert__caPay__InsufficientBalance() external {
        vm.expectRevert(ErrorsLib.InsufficientBalance.selector);
        // Becase this test script is tecnially a CA, we can call caPay directly
        evvm.caPay(COMMON_USER_NO_STAKER_2.Address, ETHER_ADDRESS, 0.1 ether);

        assertEq(
            evvm.getBalance(address(this), ETHER_ADDRESS),
            0 ether,
            "Amount should be 0 because of revert"
        );
    }
}
