// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {MultiSigWalletHandler} from "./MultiSigWalletHandler.t.sol";

contract MultiSigWalletInvariantTest is Test {
    MultiSigWallet wallet;
    MultiSigWalletHandler handler;

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

        address[3] memory ownersFixed = [owner1, owner2, owner3];
        handler = new MultiSigWalletHandler(wallet, ownersFixed);

        targetContract(address(handler));
    }

    function invariant_ConfirmationsNeverExceedOwnerCount() public view {
        uint txCount = wallet.getTransactionCount();

        for (uint i = 0; i < txCount; i++) {
            (, , , , uint numConfirmations) = wallet.getTransaction(i);
            assertLe(numConfirmations, 3);
        }
    }

    function invariant_ExecutedTransactionsHaveEnoughConfirmations() public view {
        uint txCount = wallet.getTransactionCount();

        for (uint i = 0; i < txCount; i++) {
            (, , , bool executed, uint numConfirmations) = wallet.getTransaction(i);
            if (executed) {
                assertGe(numConfirmations, wallet.numConfirmationRequired());
            }
        }
    }
}