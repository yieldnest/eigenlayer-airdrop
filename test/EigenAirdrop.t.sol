// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { EigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseTest } from "./BaseTest.t.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Vm } from "forge-std/Vm.sol";

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

        proxy = new TransparentUpgradeableProxy(
            address(airdropImplementation),
            proxyAdmin,
            initParams
        );

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
    }

    function testClaimWithPermit() public {
        vm.prank(staker);
        // airdrop.claimWithPermit(amount, 0, 0, bytes32(0), bytes32(0));
        // assertEq(EIGEN.balanceOf(staker), amount);
    }
}
