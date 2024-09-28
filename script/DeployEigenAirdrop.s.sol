// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EigenAirdrop, IEigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseScript } from "./BaseScript.s.sol";

import { ProxyAdmin } from "@openzeppelin-v5.0.2/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin-v5.0.2/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

contract DeployEigenAirdrop is BaseScript {
    EigenAirdrop public eigenAirdrop;
    EigenAirdrop public eigenAirdropImpl;
    ProxyAdmin public proxyAdmin;

    error InvalidDeployment();

    function run(string memory _path) public {
        _loadInput(_path);

        _deploy();
        _verify();
        _save();
    }

    function _deploy() internal {
        vm.startBroadcast();

        address deployer = msg.sender;
        console.log("Deployer address: ", deployer);

        eigenAirdropImpl = new EigenAirdrop();

        console.log("Deployed EigenAirdrop implementation at address: ", address(eigenAirdropImpl));

        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(eigenAirdropImpl), data.proxyAdmin, "");

        console.log("Deployed EigenAirdrop proxy at address: ", address(proxy));

        eigenAirdrop = EigenAirdrop(address(proxy));

        eigenAirdrop.initialize(
            data.airdropOwner, data.rewardsSafe, data.eigenToken, data.strategy, data.strategyManager, userAmounts
        );

        console.log("Initialized EigenAirdrop with owner: ", data.airdropOwner);

        vm.stopBroadcast();

        bytes32 ADMIN_STORAGE_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
        bytes32 value = vm.load(address(proxy), ADMIN_STORAGE_SLOT);
        proxyAdmin = ProxyAdmin(address(uint160(uint256(value))));
    }

    function _verify() internal view {
        if (proxyAdmin.owner() != data.proxyAdmin) {
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
        vm.serializeAddress(json, "eigenAirdropProxy", address(eigenAirdrop));
        vm.serializeAddress(json, "eigenAirdropImplementation", address(eigenAirdropImpl));
        vm.serializeAddress(json, "owner", data.airdropOwner);
        vm.serializeAddress(json, "proxyAdmin", address(proxyAdmin));
        vm.serializeAddress(json, "proxyAdminOwner", data.proxyAdmin);
        vm.serializeAddress(json, "rewardsSafe", data.rewardsSafe);
        vm.serializeAddress(json, "eigenToken", data.eigenToken);
        vm.serializeAddress(json, "strategy", data.strategy);
        vm.serializeUint(json, "totalPoints", totalPoints);
        vm.serializeUint(json, "totalAmount", totalAmount);
        vm.serializeUint(json, "initialSafeBalance", initialSafeBalance);
        string memory finalJson = vm.serializeAddress(json, "strategyManager", data.strategyManager);
        vm.writeJson(finalJson, _getDeploymentFile());
    }
}
