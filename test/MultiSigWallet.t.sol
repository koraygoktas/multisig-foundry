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

}