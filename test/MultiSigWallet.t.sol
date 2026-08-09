// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet wallet;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;

        wallet = new MultiSigWallet(owners, 2);

        vm.deal(address(wallet), 10 ether);
    }

    function test_OwnersAreSetCorrectly() public view {
        address[] memory owners = wallet.getOwners();
        assertEq(owners.length, 3);
        assertEq(owners[0], owner1);
        assertEq(owners[1], owner2);
        assertEq(owners[2], owner3);
    }

    function test_RequiredConfirmationsIsCorrect() public view {
        assertEq(wallet.numConfirmationRequired(), 2);
    }

   function testFuzz_DeploymentRevertsWithInvalidConfirmations(uint8 _required) public {
    vm.assume(_required == 0 || _required > 3);

    address[] memory owners = new address[](3);
    owners[0] = owner1;
    owners[1] = owner2;
    owners[2] = owner3;

    vm.expectRevert("invalid number of required confirmations");
    new MultiSigWallet(owners, _required);
}

function testFuzz_DeploymentSucceedsWithValidConfirmations(uint8 _required) public {
    vm.assume(_required > 0 && _required <= 3);

    address[] memory owners = new address[](3);
    owners[0] = owner1;
    owners[1] = owner2;
    owners[2] = owner3;

    MultiSigWallet newWallet = new MultiSigWallet(owners, _required);

    assertEq(newWallet.numConfirmationRequired(), _required);
}
function testFuzz_SubmitTransaction(address _to, uint96 _value) public {
    vm.assume(_to != address(0));
    vm.assume(_value <= 10 ether);

    vm.prank(owner1);
    wallet.submitTransaction(_to, _value, "");

    (address to, uint value, , bool executed, uint numConfirmations) = wallet.getTransaction(0);

    assertEq(to, _to);
    assertEq(value, _value);
    assertEq(executed, false);
    assertEq(numConfirmations, 0);
}
function testFuzz_ConfirmTransactionIncreasesCount(uint8 _confirmerSeed) public {
    address[3] memory owners = [owner1, owner2, owner3];
    address confirmer = owners[_confirmerSeed % 3];

    vm.prank(owner1);
    wallet.submitTransaction(address(0x99), 1 ether, "");

    vm.prank(confirmer);
    wallet.confirmTransaction(0);

    (, , , , uint numConfirmations) = wallet.getTransaction(0);
    assertEq(numConfirmations, 1);

    bool isConfirmed = wallet.isConfirmed(0, confirmer);
    assertEq(isConfirmed, true);
}
function testFuzz_ExecuteTransactionTransfersCorrectAmount(uint96 _value) public {
    vm.assume(_value > 0 && _value <= 10 ether);

    address recipient = address(0x99);
    uint recipientBalanceBefore = recipient.balance;

    vm.prank(owner1);
    wallet.submitTransaction(recipient, _value, "");

    vm.prank(owner1);
    wallet.confirmTransaction(0);

    vm.prank(owner2);
    wallet.confirmTransaction(0);

    vm.prank(owner1);
    wallet.executeTransaction(0);

    uint recipientBalanceAfter = recipient.balance;
    assertEq(recipientBalanceAfter - recipientBalanceBefore, _value);

    (, , , bool executed, ) = wallet.getTransaction(0);
    assertEq(executed, true);
}
}