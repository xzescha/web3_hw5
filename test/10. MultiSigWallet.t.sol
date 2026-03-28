// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "src/10. MultiSigWallet.sol";

contract MultiSigWalletOptimizedTest is Test {
/* YOUR SOLUTION GOES HERE */
}

// forge test --match-contract MultiSigWallet
// forge test --match-contract MultiSigWallet --gas-report
contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;
    address[] owners;
    uint256 required;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);

    function setUp() public {
        owners = [owner1, owner2, owner3];
        required = 2;

        wallet = new MultiSigWallet(owners, required);

        payable(address(wallet)).transfer(1 ether);
    }

    function testInitialization() public view {
        assertEq(wallet.owners(0), owner1);
        assertEq(wallet.owners(1), owner2);
        assertEq(wallet.owners(2), owner3);
        assertEq(wallet.required(), required);
    }

    function testSubmitTransaction() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(address(0x4), 100);
        assertEq(wallet.getTransactionCount(), 1);

        (
            uint256 transactionID,
            address destination,
            uint256 value,
            uint256 confirmationCount,
            uint256 executionTimestamp,
            bool executed
        ) = wallet.transactions(0);

        assertEq(transactionID, 0);
        assertEq(destination, address(0x4));
        assertEq(value, 100);
        assertEq(confirmationCount, 0);
        assertEq(executionTimestamp, 0);
        assertEq(executed, false);
        vm.stopPrank();
    }

    function testConfirmTransaction() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(address(0x4), 100);

        wallet.confirmTransaction(0);
        address[] memory confirmations = wallet.getConfirmations(0);
        assertEq(confirmations.length, 1);
        assertEq(confirmations[0], owner1);

        (,,, uint256 confirmationCount,,) = wallet.transactions(0);
        assertEq(confirmationCount, 1);
        vm.stopPrank();
    }

    function testExecuteTransaction() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(address(0x4), 100);

        wallet.confirmTransaction(0);
        vm.stopPrank();

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        (,,,,, bool executed) = wallet.transactions(0);
        assertTrue(executed);
    }

    function testExecutionFailure() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(address(0x4), 100 ether);

        wallet.confirmTransaction(0);
        vm.stopPrank();

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        (,,,,, bool executed) = wallet.transactions(0);
        assertFalse(executed);
    }

    function testOnlyOwnerCanSubmit() public {
        vm.prank(address(0x5));
        vm.expectRevert("Not owner");
        wallet.submitTransaction(address(0x4), 100);
    }

    function testOnlyOwnerCanConfirm() public {
        vm.prank(owner1);
        wallet.submitTransaction(address(0x4), 100);

        vm.prank(address(0x5));
        vm.expectRevert("Not owner");
        wallet.confirmTransaction(0);
    }

    function testOnlyOwnerCanExecute() public {
        vm.startPrank(owner1);
        wallet.submitTransaction(address(0x4), 100);

        wallet.confirmTransaction(0);
        vm.stopPrank();

        vm.prank(owner2);
        wallet.confirmTransaction(0);

        vm.prank(address(0x5));
        vm.expectRevert("Not owner");
        wallet.executeTransaction(0);
    }
}
