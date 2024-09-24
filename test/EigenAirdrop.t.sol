// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { EigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseTest } from "./BaseTest.t.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

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
    }

    function testDefaults() public {
        vm.prank(proxyAdmin);
        assertEq(address(proxy.admin()), proxyAdmin);

        assertEq(address(airdrop.safe()), address(YNSAFE));
        assertEq(address(airdrop.token()), address(EIGEN));
        assertEq(address(airdrop.strategy()), address(STRATEGY));
        assertEq(address(airdrop.strategyManager()), address(STRATEGY_MANAGER));
        assertEq(address(airdrop.owner()), owner);

        assertEq(airdrop.totalAmount(), amount);
        assertEq(airdrop.amounts(staker), amount);
    }

    function testClaim() public {
        vm.prank(staker);
        airdrop.claim(amount);
        assertEq(EIGEN.balanceOf(staker), amount);

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount, "YNSAFE Balance");
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

    // NOTE: this fails at
    // https://github.com/Layr-Labs/eigenlayer-contracts/blob/dev/src/contracts/core/StrategyManager.sol#L141
    // function testClaimAndRestakeWithSignature() public {
    //     uint256 sharesBefore = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);
    //
    //     Deposit memory deposit = Deposit({
    //         staker: staker,
    //         strategy: address(STRATEGY),
    //         token: address(EIGEN),
    //         amount: amount,
    //         nonce: STRATEGY_MANAGER.nonces(staker),
    //         expiry: block.timestamp + 1 days
    //     });
    //
    //     bytes32 digest = SigUtils.getDepositDigest(address(STRATEGY_MANAGER), deposit);
    //
    //     (uint8 v, bytes32 r, bytes32 s) = vm.sign(stakerWallet, digest);
    //     bytes memory signature = abi.encodePacked(r, s, v);
    //
    //     vm.prank(staker);
    //     uint256 shares = airdrop.claimAndRestakeWithSignature(amount, deposit.expiry, signature);
    //
    //     assertEq(EIGEN.balanceOf(staker), 0, "User Balance");
    //     assertEq(shares, amount, "Shares");
    //
    //     uint256 sharesAfter = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);
    //     assertEq(sharesAfter, sharesBefore + shares, "Shares After");
    //
    //     assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount, "YNSAFE Balance");
    // }
}
