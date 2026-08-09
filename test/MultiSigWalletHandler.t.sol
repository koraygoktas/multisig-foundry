// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletHandler is Test {
    MultiSigWallet public wallet;
    address[3] public owners;

    constructor(MultiSigWallet _wallet, address[3] memory _owners) {
        wallet = _wallet;
        owners = _owners;
    }

    function submit(uint96 _value, uint8 _ownerSeed) public {
        address sender = owners[_ownerSeed % 3];
        uint96 boundedValue = uint96(bound(_value, 0, 1 ether));

        vm.prank(sender);
        wallet.submitTransaction(address(0x99), boundedValue, "");
    }

    function confirm(uint8 _ownerSeed, uint8 _txSeed) public {
        uint txCount = wallet.getTransactionCount();
        if (txCount == 0) return;

        address sender = owners[_ownerSeed % 3];
        uint txIndex = _txSeed % txCount;

        vm.prank(sender);
        try wallet.confirmTransaction(txIndex) {} catch {}
    }

    function revoke(uint8 _ownerSeed, uint8 _txSeed) public {
        uint txCount = wallet.getTransactionCount();
        if (txCount == 0) return;

        address sender = owners[_ownerSeed % 3];
        uint txIndex = _txSeed % txCount;

        vm.prank(sender);
        try wallet.revokeConfirmation(txIndex) {} catch {}
    }

    function execute(uint8 _ownerSeed, uint8 _txSeed) public {
        uint txCount = wallet.getTransactionCount();
        if (txCount == 0) return;

        address sender = owners[_ownerSeed % 3];
        uint txIndex = _txSeed % txCount;

        vm.prank(sender);
        try wallet.executeTransaction(txIndex) {} catch {}
    }
}