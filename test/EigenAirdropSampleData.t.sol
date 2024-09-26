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

struct EigenPoints {
    address addr;
    uint256 points;
}

contract EigenAirdropSampleDataTest is BaseTest {
    EigenAirdrop public airdropImplementation;
    EigenAirdrop public airdrop;
    TransparentUpgradeableProxy public proxy;

    address public proxyAdmin = makeAddr("proxyAdmin");
    address public owner = makeAddr("owner");
    uint256 public amount = 1_000_000_000_000_000_000;

    UserAmount[] public sampleUserAmounts;
    uint256 public sampleTotalAmounts;

    function setUp() public override {
        super.setUp();

        airdropImplementation = new EigenAirdrop();

        UserAmount[] memory userAmounts = new UserAmount[](0);

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

        _loadSample();
    }

    function _loadSample() internal {
        string memory path = string(abi.encodePacked(vm.projectRoot(), "/test/utils/sample.json"));
        string memory json = vm.readFile(path);

        bytes memory parsedEigenPoints = vm.parseJson(json, ".eigenPoints");
        EigenPoints[] memory eigenPoints = abi.decode(parsedEigenPoints, (EigenPoints[]));

        uint256 totalPoints;
        for (uint256 i; i < eigenPoints.length; i++) {
            totalPoints += eigenPoints[i].points;
        }

        UserAmount memory tempUserAmount;
        for (uint256 i; i < eigenPoints.length; i++) {
            if (eigenPoints[i].points == 0) {
                continue;
            }
            tempUserAmount.user = eigenPoints[i].addr;
            tempUserAmount.amount = Math.mulDiv(eigenPoints[i].points, INITIAL_BALANCE, totalPoints);

            sampleUserAmounts.push(tempUserAmount);
            sampleTotalAmounts += tempUserAmount.amount;
        }

        assertEq(sampleTotalAmounts <= INITIAL_BALANCE, true, "Total Amounts");
        assertEq(sampleUserAmounts.length > 0, true, "Sample User Amounts");
    }

    function testUpdateUserAmountsWithSampleData() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        vm.prank(owner);
        airdrop.updateUserAmounts(sampleUserAmounts);

        for (uint256 i; i < sampleUserAmounts.length; i++) {
            assertEq(airdrop.amounts(sampleUserAmounts[i].user), sampleUserAmounts[i].amount);
        }
    }

    function testClaimWithSampleData() public {
        vm.prank(owner);
        airdrop.pause();
        assertEq(airdrop.paused(), true);

        vm.prank(owner);
        airdrop.updateUserAmounts(sampleUserAmounts);

        vm.prank(owner);
        airdrop.unpause();
        assertEq(airdrop.paused(), false);

        uint256 numberOfUsers = sampleUserAmounts.length;
        if (numberOfUsers > 100) {
            numberOfUsers = 100;
        }

        uint256 claimedAmount;
        for (uint256 i; i < numberOfUsers; i++) {
            if (sampleUserAmounts[i].amount == 0) {
                continue;
            }

            uint256 beforeBalance = EIGEN.balanceOf(sampleUserAmounts[i].user);

            vm.prank(sampleUserAmounts[i].user);
            airdrop.claim(sampleUserAmounts[i].amount);

            uint256 afterBalance = EIGEN.balanceOf(sampleUserAmounts[i].user);
            assertEq(afterBalance - beforeBalance, sampleUserAmounts[i].amount);

            claimedAmount += sampleUserAmounts[i].amount;
        }

        assertEq(EIGEN.balanceOf(YNSAFE), INITIAL_BALANCE - claimedAmount, "YNSAFE Balance");
    }

    function testDeployWithSampleData() public {
        bytes memory initParams = abi.encodeWithSelector(
            EigenAirdrop.initialize.selector,
            address(owner),
            address(YNSAFE),
            address(EIGEN),
            address(STRATEGY),
            address(STRATEGY_MANAGER),
            sampleUserAmounts
        );

        new TransparentUpgradeableProxy(address(airdropImplementation), proxyAdmin, initParams);
    }
}
