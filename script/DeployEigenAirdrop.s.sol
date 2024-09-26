// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EigenAirdrop, IEigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseScript } from "./BaseScript.s.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

contract DeployEigenAirdrop is BaseScript {
    EigenAirdrop public eigenAirdrop;

    error InvalidDeployment();

    function run(string memory _path) public {
        _loadInput(_path);

        _deploy();
        _verify();
        _save();
    }

    function _deploy() internal {
        bytes memory initParams = abi.encodeWithSelector(
            EigenAirdrop.initialize.selector,
            data.airdropOwner,
            data.rewardsSafe,
            data.eigenToken,
            data.strategy,
            data.strategyManager,
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
        if (eigenAirdrop.totalAmount() != totalAmounts) {
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
        string memory json;
        vm.serializeAddress(json, "eigenAirdrop", address(eigenAirdrop));
        vm.serializeAddress(json, "owner", data.airdropOwner);
        vm.serializeAddress(json, "proxyAdmin", data.proxyAdmin);
        vm.serializeAddress(json, "rewardsSafe", data.rewardsSafe);
        vm.serializeAddress(json, "eigenToken", data.eigenToken);
        vm.serializeAddress(json, "strategy", data.strategy);
        vm.serializeUint(json, "totalPoints", totalPoints);
        vm.serializeUint(json, "totalAmounts", totalAmounts);
        vm.serializeUint(json, "initialSafeBalance", initialSafeBalance);
        string memory finalJson = vm.serializeAddress(json, "strategyManager", data.strategyManager);
        vm.writeJson(finalJson, _getDeploymentFile());
    }
}
