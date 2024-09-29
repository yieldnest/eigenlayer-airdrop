// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { BaseTest } from "./BaseTest.t.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EigenTransferAndStakeTest is BaseTest {
    address internal staker = makeAddr("staker");
    uint256 internal amount = 1_000_000_000_000_000_000;

    function testDefaults() external view {
        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE, "YNSAFE Balance");
        assertEq(EIGEN.balanceOf(staker), 0, "User Balance");

        assertEq(EIGEN.allowedFrom(YNSAFE), true, "Allowed From YNSAFE");
        assertEq(EIGEN.allowedTo(YNSAFE), false, "Not Allowed To YNSAFE");

        assertEq(EIGEN.allowedFrom(staker), false, "Not Allowed From User");
        assertEq(EIGEN.allowedTo(staker), false, "Not Allowed To User");
    }

    function testTransferToUser() external {
        vm.prank(YNSAFE);
        EIGEN.transfer(staker, amount);
        assertEq(EIGEN.balanceOf(staker), amount, "User Balance");

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount, "YNSAFE Balance");
    }

    function testTransferFailsFromUser() external {
        vm.prank(YNSAFE);
        EIGEN.transfer(staker, amount);
        assertEq(EIGEN.balanceOf(staker), amount, "User Balance");

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - amount, "YNSAFE Balance");

        vm.expectRevert();
        vm.prank(staker);
        EIGEN.transfer(YNSAFE, amount);
    }

    function testStakeFailsWithoutBalance() external {
        vm.expectRevert();
        vm.prank(staker);
        STRATEGY_MANAGER.depositIntoStrategy(STRATEGY, IERC20(address(EIGEN)), amount);
    }

    function testStakeFromUser() external {
        uint256 sharesBefore = STRATEGY_MANAGER.stakerStrategyShares(staker, STRATEGY);

        vm.prank(YNSAFE);
        EIGEN.transfer(staker, amount);
        assertEq(EIGEN.balanceOf(staker), amount, "User Balance");

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
}
