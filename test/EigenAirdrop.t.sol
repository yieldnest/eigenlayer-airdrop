// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { EigenAirdrop } from "../src/EigenAirdrop.sol";
import { IEigenAirdrop, UserAmount } from "../src/IEigenAirdrop.sol";

import { BaseTest } from "./BaseTest.t.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { OwnableUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin-upgradeable-v5.0.2/utils/PausableUpgradeable.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Vm } from "forge-std/Vm.sol";

import { Deposit, SigUtils } from "./utils/SigUtils.sol";

contract EigenAirdropTest is BaseTest {
    EigenAirdrop public airdrop;
    TransparentUpgradeableProxy public proxy;

    address public proxyAdmin = makeAddr("proxyAdmin");
    address public owner = makeAddr("owner");
    uint256 public amount = 1_000_000_000_000_000_000;

    Vm.Wallet public stakerWallet;
    address public staker;

    address public strategyWhitelister;

    function setUp() public override {
        super.setUp();

        stakerWallet = vm.createWallet("staker");
        staker = stakerWallet.addr;

        EigenAirdrop airdropImplementation = new EigenAirdrop();

        UserAmount[] memory userAmounts = new UserAmount[](1);
        userAmounts[0] = UserAmount({ user: staker, amount: amount });

        bytes memory initParams = abi.encodeWithSelector(
            EigenAirdrop.initialize.selector,
            address(owner),
            address(YNSAFE),
            address(EIGEN),
            address(STRATEGY),
            address(STRATEGY_MANAGER),
            userAmounts
        );

        proxy = new TransparentUpgradeableProxy(address(airdropImplementation), proxyAdmin, initParams);

        airdrop = EigenAirdrop(address(proxy));

        vm.prank(YNSAFE);
        EIGEN.approve(address(airdrop), INITIAL_BALANCE);

        strategyWhitelister = STRATEGY_MANAGER.strategyWhitelister();
    }

    function testDefaults() public {
        vm.prank(proxyAdmin);
        assertEq(address(proxy.admin()), proxyAdmin);

        assertEq(address(airdrop.safe()), address(YNSAFE));
        assertEq(address(airdrop.token()), address(EIGEN));
        assertEq(address(airdrop.strategy()), address(STRATEGY));
        assertEq(address(airdrop.strategyManager()), address(STRATEGY_MANAGER));
        assertEq(address(airdrop.owner()), owner);
        assertEq(airdrop.paused(), false);

        assertEq(airdrop.amounts(staker), amount);
    }

    function testPause() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);
    }

    function testPauseRevertsNotOwner() public {
        bytes memory revertData =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(this));
        vm.expectRevert(revertData);
        airdrop.pause();
    }

    function testPauseRevertsAlreadyPaused() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(owner);
        airdrop.pause();
    }

    function testUnpause() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        vm.prank(owner);
        airdrop.unpause();
        assertEq(airdrop.paused(), false);
    }

    function testUnpauseRevertsNotOwner() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        bytes memory revertData =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(this));
        vm.expectRevert(revertData);
        airdrop.unpause();
    }

    function testUnpauseRevertsNotPaused() public {
        vm.expectRevert(PausableUpgradeable.ExpectedPause.selector);
        vm.prank(owner);
        airdrop.unpause();
    }

    function testClaim() public {
        vm.prank(staker);
        airdrop.claim(amount);
        assertEq(EIGEN.balanceOf(staker), amount);

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount, "YNSAFE Balance");
    }

    function testClaimRevertsIfPaused() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(staker);
        airdrop.claim(amount);

        assertEq(EIGEN.balanceOf(staker), 0);
    }

    function testClaimRevertsIfAmountZero() public {
        vm.expectRevert(IEigenAirdrop.NoAirdrop.selector);
        vm.prank(staker);
        airdrop.claim(0);

        assertEq(EIGEN.balanceOf(staker), 0);
    }

    function testClaimRevertsIfAmountExceeds() public {
        vm.expectRevert(IEigenAirdrop.NoAirdrop.selector);
        vm.prank(staker);
        airdrop.claim(amount * 2);

        assertEq(EIGEN.balanceOf(staker), 0);
    }

    function testClaimThenStake() public {
        uint256 sharesBefore = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);

        vm.prank(staker);
        airdrop.claim(amount);
        assertEq(EIGEN.balanceOf(staker), amount);

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount, "YNSAFE Balance");

        vm.prank(staker);
        EIGEN.approve(address(STRATEGY_MANAGER), amount);

        vm.prank(staker);
        uint256 shares = STRATEGY_MANAGER.depositIntoStrategy(STRATEGY, IERC20(address(EIGEN)), amount);

        assertEq(EIGEN.balanceOf(staker), 0, "User Balance");
        assertEq(shares, amount, "Shares");

        uint256 sharesAfter = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);
        assertEq(sharesAfter, sharesBefore + shares, "Shares After");
    }

    function testClaimAndRestakeWithSignature() public {
        bool forbidden = STRATEGY_MANAGER.thirdPartyTransfersForbidden(STRATEGY);
        assertEq(forbidden, true, "Third party transfers are not forbidden");

        vm.prank(strategyWhitelister);
        STRATEGY_MANAGER.setThirdPartyTransfersForbidden(STRATEGY, false);

        forbidden = STRATEGY_MANAGER.thirdPartyTransfersForbidden(STRATEGY);
        assertEq(forbidden, false, "Third party transfers are forbidden");

        uint256 sharesBefore = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);

        Deposit memory deposit = Deposit({
            staker: staker,
            strategy: address(STRATEGY),
            token: address(EIGEN),
            amount: amount,
            nonce: STRATEGY_MANAGER.nonces(staker),
            expiry: block.timestamp + 1 days
        });

        bytes32 digest = SigUtils.getDepositDigest(address(STRATEGY_MANAGER), deposit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(stakerWallet, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(staker);
        uint256 shares = airdrop.claimAndRestakeWithSignature(amount, deposit.expiry, signature);

        assertEq(EIGEN.balanceOf(staker), 0, "User Balance");
        assertEq(shares, amount, "Shares");

        uint256 sharesAfter = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);
        assertEq(sharesAfter, sharesBefore + shares, "Shares After");

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount, "YNSAFE Balance");
    }

    function testClaimAndRestakeWithSignatureRevertsAfterSignatureExpiry() public {
        bool forbidden = STRATEGY_MANAGER.thirdPartyTransfersForbidden(STRATEGY);
        assertEq(forbidden, true, "Third party transfers are not forbidden");

        vm.prank(strategyWhitelister);
        STRATEGY_MANAGER.setThirdPartyTransfersForbidden(STRATEGY, false);

        forbidden = STRATEGY_MANAGER.thirdPartyTransfersForbidden(STRATEGY);
        assertEq(forbidden, false, "Third party transfers are forbidden");

        uint256 sharesBefore = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);

        Deposit memory deposit = Deposit({
            staker: staker,
            strategy: address(STRATEGY),
            token: address(EIGEN),
            amount: amount,
            nonce: STRATEGY_MANAGER.nonces(staker),
            expiry: block.timestamp + 10 minutes
        });

        bytes32 digest = SigUtils.getDepositDigest(address(STRATEGY_MANAGER), deposit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(stakerWallet, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.warp(block.timestamp + 20 minutes);

        vm.expectRevert("StrategyManager.depositIntoStrategyWithSignature: signature expired");
        vm.prank(staker);
        airdrop.claimAndRestakeWithSignature(amount, deposit.expiry, signature);

        assertEq(EIGEN.balanceOf(staker), 0, "User Balance");

        uint256 sharesAfter = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);
        assertEq(sharesAfter, sharesBefore, "Shares After");

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE, "YNSAFE Balance");
    }

    function testClaimAndRestakeWithSignatureRevertsIfPaused() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        Deposit memory deposit = Deposit({
            staker: staker,
            strategy: address(STRATEGY),
            token: address(EIGEN),
            amount: amount,
            nonce: STRATEGY_MANAGER.nonces(staker),
            expiry: block.timestamp + 1 days
        });

        bytes32 digest = SigUtils.getDepositDigest(address(STRATEGY_MANAGER), deposit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(stakerWallet, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(staker);
        airdrop.claimAndRestakeWithSignature(amount, deposit.expiry, signature);

        assertEq(EIGEN.balanceOf(staker), 0, "User Balance");

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE, "YNSAFE Balance");
    }

    function testUpdateUserAmounts() public {
        UserAmount[] memory userAmounts = new UserAmount[](1);
        userAmounts[0] = UserAmount({ user: staker, amount: amount * 2 });

        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        vm.prank(owner);
        airdrop.updateUserAmounts(userAmounts);

        assertEq(airdrop.amounts(staker), amount * 2);
    }

    function testUpdateUserAmountsRevertsNotOwner() public {
        UserAmount[] memory userAmounts = new UserAmount[](1);
        userAmounts[0] = UserAmount({ user: staker, amount: amount * 2 });

        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        bytes memory revertData =
            abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(this));
        vm.expectRevert(revertData);
        airdrop.updateUserAmounts(userAmounts);
    }

    function testUpdateUserAmountsRevertsIfNotPaused() public {
        UserAmount[] memory userAmounts = new UserAmount[](1);
        userAmounts[0] = UserAmount({ user: staker, amount: amount * 2 });

        vm.expectRevert(PausableUpgradeable.ExpectedPause.selector);
        vm.prank(owner);
        airdrop.updateUserAmounts(userAmounts);
    }

    function testClaimAmountAfterUpdateUserAmounts() public {
        UserAmount[] memory userAmounts = new UserAmount[](1);
        userAmounts[0] = UserAmount({ user: staker, amount: amount * 2 });

        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        vm.prank(owner);
        airdrop.updateUserAmounts(userAmounts);

        vm.prank(owner);
        airdrop.unpause();
        assertEq(airdrop.paused(), false);

        vm.prank(staker);
        airdrop.claim(amount * 2);
        assertEq(EIGEN.balanceOf(staker), amount * 2);

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount * 2, "YNSAFE Balance");
    }
}
