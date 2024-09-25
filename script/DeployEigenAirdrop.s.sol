// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EigenAirdrop, IEigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseScript } from "./BaseScript.s.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { console } from "forge-std/console.sol";

contract DeployEigenAirdrop is BaseScript {
    uint256 public totalPoints;

    uint256 public airdropDeadline;
    UserAmount[] public userAmounts;
    uint256 public totalAmount;

    EigenAirdrop public eigenAirdrop;

    error InvalidDeployment();

    function _calculateUserAmounts() internal {
        // get total points
        for (uint256 i; i < eigenPoints.length; i++) {
            totalPoints += eigenPoints[i].points;
        }

        //create user amounts
        UserAmount memory tempUserAmount;
        for (uint256 i; i < eigenPoints.length; i++) {
            if (eigenPoints[i].points == 0) {
                continue;
            }
            tempUserAmount.user = eigenPoints[i].addr;
            tempUserAmount.amount = Math.mulDiv(eigenPoints[i].points, initialSafeBalance, totalPoints);

            userAmounts.push(tempUserAmount);
            totalAmount += tempUserAmount.amount;
        }

        if (totalAmount > initialSafeBalance) {
            revert InvalidInput();
        }
        if (userAmounts.length == 0) {
            revert InvalidInput();
        }
    }

    function run(string memory _path) public {
        _loadInput(_path);
        _calculateUserAmounts();

        _deploy();
        _verify();
        _save();
    }

    function _deploy() internal {
        // TODO: take deadline from input
        airdropDeadline = block.timestamp + 30 days;

        bytes memory initParams = abi.encodeWithSelector(
            EigenAirdrop.initialize.selector,
            data.airdropOwner,
            data.rewardsSafe,
            data.eigenToken,
            data.strategy,
            data.strategyManager,
            airdropDeadline,
            userAmounts
        );

        vm.startBroadcast();

        // TODO: remove deterministic deployment if not needed
        EigenAirdrop eigenAirdropImpl = new EigenAirdrop{ salt: _SALT }();

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy{ salt: _SALT }(address(eigenAirdropImpl), data.proxyAdmin, initParams);

        vm.stopBroadcast();

        eigenAirdrop = EigenAirdrop(address(proxy));

        console.log("Deployed EigenAirdrop at address: ", address(eigenAirdrop));
    }

    function _verify() internal view {
        if (eigenAirdrop.totalAmount() != totalAmount) {
            revert InvalidDeployment();
        }
        if (eigenAirdrop.deadline() != airdropDeadline) {
            revert InvalidDeployment();
        }
        if (eigenAirdrop.owner() != data.airdropOwner) {
            revert InvalidDeployment();
        }
        if (eigenAirdrop.safe() != data.rewardsSafe) {
            revert InvalidDeployment();
        }
        if (address(eigenAirdrop.token()) != data.eigenToken) {
            revert InvalidDeployment();
        }
        if (eigenAirdrop.paused()) {
            revert InvalidDeployment();
        }
    }

    function _save() internal {
        // TODO: save deployment to file
    }
}
