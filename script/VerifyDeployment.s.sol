// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EigenAirdrop, IEigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseScript } from "./BaseScript.s.sol";

import { ProxyAdmin } from "lib/openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from
    "lib/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Address } from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import { Strings } from "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

contract VerifyEigenAirdrop is BaseScript {
    EigenAirdrop public eigenAirdrop;
    EigenAirdrop public eigenAirdropImpl;
    ProxyAdmin public proxyAdmin;

    error InvalidDeployment();

    function run(string memory _path) public {
        _loadInput(_path);

        _verify();
    }

    function _verify() internal view {

        string memory deploymentFile = _getDeploymentFile();
        string memory json = vm.readFile(deploymentFile);
        Deployment memory deployment = abi.decode(vm.parseJson(json), (Deployment));

        console.log("Loaded deployment from:", deploymentFile);
        console.log("EigenAirdrop Proxy:", deployment.eigenAirdropProxy);
        console.log("EigenAirdrop Implementation:", deployment.eigenAirdropImplementation);
        // console.log("Proxy Admin:", deployment.proxyAdmin);
        // console.log("Owner:", deployment.owner);
        // console.log("Proxy Admin Owner:", deployment.proxyAdminOwner);
        // console.log("Rewards Safe:", deployment.rewardsSafe);
        // console.log("Eigen Token:", deployment.eigenToken);
        // console.log("Strategy:", deployment.strategy);
        // console.log("Strategy Manager:", deployment.strategyManager);
        // console.log("Total Points:", deployment.totalPoints);
        // console.log("Total Amount:", deployment.totalAmount);
        // console.log("Initial Safe Balance:", deployment.initialSafeBalance);

        return;


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

        return;

        // Verify user amounts
        for (uint256 i = 0; i < userAmounts.length; i++) {
            UserAmount memory userAmount = userAmounts[i];
            uint256 onChainAmount = eigenAirdrop.amounts(userAmount.user);
            if (onChainAmount != userAmount.amount) {
                console.log("Mismatch for user: ", userAmount.user);
                console.log("Expected amount: ", userAmount.amount);
                console.log("On-chain amount: ", onChainAmount);
                revert InvalidDeployment();
            }
        }

        console.log("Deployment verified successfully");
    }

    struct Deployment {
        address eigenAirdropProxy;
        address eigenAirdropImplementation;
        address proxyAdmin;
        address owner;
        address proxyAdminOwner;
        address rewardsSafe;
        address eigenToken;
        address strategy;
        address strategyManager;
        uint256 totalPoints;
        uint256 totalAmount;
        uint256 initialSafeBalance;
    }

    function _loadDeployment() internal view returns (Deployment memory) {
        string memory json = vm.readFile(_getDeploymentFile());
        
        return Deployment({
            eigenAirdropProxy: abi.decode(vm.parseJson(json, ".eigenAirdropProxy"), (address)),
            eigenAirdropImplementation: abi.decode(vm.parseJson(json, ".eigenAirdropImplementation"), (address)),
            proxyAdmin: abi.decode(vm.parseJson(json, ".proxyAdmin"), (address)),
            owner: abi.decode(vm.parseJson(json, ".owner"), (address)),
            proxyAdminOwner: abi.decode(vm.parseJson(json, ".proxyAdminOwner"), (address)),
            rewardsSafe: abi.decode(vm.parseJson(json, ".rewardsSafe"), (address)),
            eigenToken: abi.decode(vm.parseJson(json, ".eigenToken"), (address)),
            strategy: abi.decode(vm.parseJson(json, ".strategy"), (address)),
            strategyManager: abi.decode(vm.parseJson(json, ".strategyManager"), (address)),
            totalPoints: abi.decode(vm.parseJson(json, ".totalPoints"), (uint256)),
            totalAmount: abi.decode(vm.parseJson(json, ".totalAmount"), (uint256)),
            initialSafeBalance: abi.decode(vm.parseJson(json, ".initialSafeBalance"), (uint256))
        });
    }
}