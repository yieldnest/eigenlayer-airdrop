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

    function _verify() internal {

        string memory deploymentFile = _getDeploymentFile();
        string memory json = vm.readFile(deploymentFile);
        Deployment memory deployment = _loadDeployment();

        console.log("Loaded deployment from:", deploymentFile);
        console.log("EigenAirdrop Proxy:", deployment.eigenAirdropProxy);
        console.log("EigenAirdrop Implementation:", deployment.eigenAirdropImplementation);
        console.log("Proxy Admin:", deployment.proxyAdmin);
        console.log("Owner:", deployment.owner);
        console.log("Proxy Admin Owner:", deployment.proxyAdminOwner);
        console.log("Rewards Safe:", deployment.rewardsSafe);
        console.log("Eigen Token:", deployment.eigenToken);
        console.log("Strategy:", deployment.strategy);
        console.log("Strategy Manager:", deployment.strategyManager);
        console.log("Total Points:", deployment.totalPoints);
        console.log("Total Amount:", deployment.totalAmount);
        console.log("Initial Safe Balance:", deployment.initialSafeBalance);


        // Verify ProxyAdmin owner using Utils
        address proxyAdminAddress = getTransparentUpgradeableProxyAdminAddress(deployment.eigenAirdropProxy);
        proxyAdmin = ProxyAdmin(proxyAdminAddress);
        
        if (proxyAdmin.owner() != deployment.proxyAdminOwner) {
            console.log("Expected ProxyAdmin owner:", deployment.proxyAdminOwner);
            console.log("Actual ProxyAdmin owner:", proxyAdmin.owner());
            revert InvalidDeployment();
        }
        
        console.log("\u2705 ProxyAdmin owner verified successfully: ", proxyAdmin.owner());

        // Initialize EigenAirdrop instance
        eigenAirdrop = EigenAirdrop(deployment.eigenAirdropProxy);

        if (eigenAirdrop.owner() != data.airdropOwner) {
            revert("EigenAirdrop owner verification failed");
        }
        console.log("\u2705 EigenAirdrop owner verified successfully: ", eigenAirdrop.owner());

        if (eigenAirdrop.safe() != data.rewardsSafe) {
            revert("EigenAirdrop safe address verification failed");
        }
        console.log("\u2705 EigenAirdrop safe address verified successfully: ", eigenAirdrop.safe());

        if (address(eigenAirdrop.token()) != data.eigenToken) {
            revert("EigenAirdrop token address verification failed");
        }
        console.log("\u2705 EigenAirdrop token address verified successfully: ", address(eigenAirdrop.token()));

        if (eigenAirdrop.paused()) {
            revert("EigenAirdrop is paused when it should not be");
        }
        console.log("\u2705 EigenAirdrop is not paused");


        // Verify user amounts
        uint256 totalTokens = 0;
        for (uint256 i = 0; i < userAmounts.length; i++) {
            UserAmount memory userAmount = userAmounts[i];
            uint256 onChainAmount = eigenAirdrop.amounts(userAmount.user);
            if (onChainAmount != userAmount.amount) {
                console.log("Mismatch for user: ", userAmount.user);
                console.log("Expected amount: ", userAmount.amount);
                console.log("On-chain amount: ", onChainAmount);
                revert InvalidDeployment();
            }
            totalTokens += onChainAmount;
        }
        
        if (totalTokens != deployment.totalAmount) {
            console.log("Total tokens mismatch");
            console.log("Expected total tokens: ", deployment.totalAmount);
            console.log("Actual total tokens: ", totalTokens);
            revert InvalidDeployment();
        }
        console.log("\u2705 Total tokens verified successfully");
        console.log("Total tokens: ", totalTokens);

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
        address eigenAirdropProxy = abi.decode(vm.parseJson(json, ".eigenAirdropProxy"), (address));


        address eigenAirdropImplementation = abi.decode(vm.parseJson(json, ".eigenAirdropImplementation"), (address));
        address proxyAdmin = abi.decode(vm.parseJson(json, ".proxyAdmin"), (address));
        address owner = abi.decode(vm.parseJson(json, ".owner"), (address));
        address proxyAdminOwner = abi.decode(vm.parseJson(json, ".proxyAdminOwner"), (address));
        address rewardsSafe = abi.decode(vm.parseJson(json, ".rewardsSafe"), (address));
        address eigenToken = abi.decode(vm.parseJson(json, ".eigenToken"), (address));
        address strategy = abi.decode(vm.parseJson(json, ".strategy"), (address));
        address strategyManager = abi.decode(vm.parseJson(json, ".strategyManager"), (address));
        uint256 totalPoints = abi.decode(vm.parseJson(json, ".totalPoints"), (uint256));
        uint256 totalAmount = abi.decode(vm.parseJson(json, ".totalAmount"), (uint256));
        uint256 initialSafeBalance = abi.decode(vm.parseJson(json, ".initialSafeBalance"), (uint256));

        return Deployment({
            eigenAirdropProxy: eigenAirdropProxy,
            eigenAirdropImplementation: eigenAirdropImplementation,
            proxyAdmin: proxyAdmin,
            owner: owner,
            proxyAdminOwner: proxyAdminOwner,
            rewardsSafe: rewardsSafe,
            eigenToken: eigenToken,
            strategy: strategy,
            strategyManager: strategyManager,
            totalPoints: totalPoints,
            totalAmount: totalAmount,
            initialSafeBalance: initialSafeBalance
        });
    }
}