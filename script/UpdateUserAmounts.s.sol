// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EigenAirdrop, IEigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseScript } from "./BaseScript.s.sol";
import { TransparentUpgradeableProxy } from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { console } from "forge-std/console.sol";

contract UpdateUserAmounts is BaseScript {
    EigenAirdrop public eigenAirdrop;
    EigenAirdrop public eigenAirdropImpl;

    error InvalidDeployment();

    function run() public {

        // Load user amounts from the JSON file
        _loadInput("script/inputs/season-one-eigen-holesky.json");


        address deployer = msg.sender;
        console.log("Deployer address: ", deployer);

        // Start broadcasting transactions
        vm.startBroadcast();

        // Create an instance of the EigenAirdrop contract at the specified address
        eigenAirdrop = EigenAirdrop(0xEedc5467f6cc6736f5A97722cc1c8382A32170c5);



        // Call updateUserAmounts with the loaded user amounts
        eigenAirdrop.updateUserAmounts(userAmounts);


        // Stop broadcasting transactions
        vm.stopBroadcast();

        console.log("User amounts updated successfully for EigenAirdrop at", address(eigenAirdrop));
    }
}