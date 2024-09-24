// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { StrategyManager } from "eigenlayer-contracts/core/StrategyManager.sol";
import { EigenStrategy } from "eigenlayer-contracts/strategies/EigenStrategy.sol";
import { Eigen } from "eigenlayer-contracts/token/Eigen.sol";
import { Test } from "forge-std/Test.sol";

contract EigenTransferAndStakeTest is Test {
    error AlchemyAPIKeyNotSet();

    Eigen internal constant EIGEN = Eigen(0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83);
    address internal constant YNSAFE = 0xCCB2FEB7d8e081dcedFe1CFbefC9d46Eb383E389;
    StrategyManager internal constant STRATEGY_MANAGER =
        StrategyManager(0x858646372CC42E1A627fcE94aa7A7033e7CF075A);
    EigenStrategy internal constant STRATEGY = EigenStrategy(0xaCB55C530Acdb2849e6d4f36992Cd8c9D50ED8F7);

    address internal user = makeAddr("user");

    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        if (bytes(alchemyApiKey).length == 0) {
            revert AlchemyAPIKeyNotSet();
        }

        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_817_714 });
    }

    function testDefaults() external view {
        assertEq(EIGEN.balanceOf(YNSAFE), 124_459_120_634_647_860_000_000, "YNSAFE Balance");
        assertEq(EIGEN.balanceOf(user), 0, "User Balance");

        assertEq(EIGEN.allowedFrom(YNSAFE), true, "Allowed From YNSAFE");
        assertEq(EIGEN.allowedTo(YNSAFE), false, "Not Allowed To YNSAFE");

        assertEq(EIGEN.allowedFrom(user), false, "Not Allowed From User");
        assertEq(EIGEN.allowedTo(user), false, "Not Allowed To User");
    }

    function testTransferToUser() external {
        vm.prank(YNSAFE);
        EIGEN.transfer(user, 1_000_000_000_000_000_000);
        assertEq(EIGEN.balanceOf(user), 1_000_000_000_000_000_000, "User Balance");

        assertEq(
            EIGEN.balanceOf(YNSAFE), 124_459_120_634_647_860_000_000 - 1_000_000_000_000_000_000, "YNSAFE Balance"
        );
    }

    function testTransferFailsFromUser() external {
        vm.prank(YNSAFE);
        EIGEN.transfer(user, 1_000_000_000_000_000_000);
        assertEq(EIGEN.balanceOf(user), 1_000_000_000_000_000_000, "User Balance");

        assertEq(
            EIGEN.balanceOf(YNSAFE), 124_459_120_634_647_860_000_000 - 1_000_000_000_000_000_000, "YNSAFE Balance"
        );

        vm.expectRevert();
        vm.prank(user);
        EIGEN.transfer(YNSAFE, 1_000_000_000_000_000_000);
    }

    function testStakeFailsWithoutBalance() external {
        vm.expectRevert();
        vm.prank(user);
        STRATEGY_MANAGER.depositIntoStrategy(STRATEGY, IERC20(address(EIGEN)), 1_000_000_000_000_000_000);
    }

    function testStakeFromUser() external {
        uint256 sharesBefore = STRATEGY_MANAGER.stakerStrategyShares(user, STRATEGY);

        vm.prank(YNSAFE);
        EIGEN.transfer(user, 1_000_000_000_000_000_000);
        assertEq(EIGEN.balanceOf(user), 1_000_000_000_000_000_000, "User Balance");

        assertEq(
            EIGEN.balanceOf(YNSAFE), 124_459_120_634_647_860_000_000 - 1_000_000_000_000_000_000, "YNSAFE Balance"
        );

        vm.prank(user);
        EIGEN.approve(address(STRATEGY_MANAGER), 1_000_000_000_000_000_000);

        vm.prank(user);
        uint256 shares =
            STRATEGY_MANAGER.depositIntoStrategy(STRATEGY, IERC20(address(EIGEN)), 1_000_000_000_000_000_000);

        assertEq(EIGEN.balanceOf(user), 0, "User Balance");
        assertEq(shares, 1_000_000_000_000_000_000, "Shares");

        uint256 sharesAfter = STRATEGY_MANAGER.stakerStrategyShares(user, STRATEGY);
        assertEq(sharesAfter, sharesBefore + shares, "Shares After");
    }
}
