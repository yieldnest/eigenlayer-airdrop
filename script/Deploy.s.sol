// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { EigenAirdrop, IEigenAirdrop, UserAmount } from "../src/EigenAirdrop.sol";

import { BaseScript, EigenAmounts } from "./Base.s.sol";


contract DeployEigenAirdrop is BaseScript {
    
    uint256 public totalPoints;
    
    uint256 public tokensPerPoint;
    uint256 public airdropDeadline = block.timestamp + 30 days;
    UserAmount[] public userAmounts;

    function _getUserAmounts()internal {
        UserAmount memory tempUserAmount;
        EigenAmounts memory tempEigenAmount;
        // get total points
        for(uint256 i; i < eigenAmounts.length; i++){
            totalPoints+= eigenAmounts[i].points;
        }
        // get tokens per point
        tokensPerPoint = multisigBalance / totalPoints;
        //create user amounts
        for(uint256 i; i < eigenAmounts.length; i++){
            tempEigenAmount = eigenAmounts[i];
            tempUserAmount.user = tempEigenAmount.addr;
            tempUserAmount.amount = tempEigenAmount.points * tokensPerPoint;
            userAmounts.push(tempUserAmount);
        } 

    }

    function run(string memory _path) public returns (EigenAirdrop eigenAirdrop) {
        _loadEigenAmounts(_path);
        _getUserAmounts();
        eigenAirdrop = new EigenAirdrop();

        require(userAmounts.length > 0);
        //  UserAmount[] memory _userAmounts = userAmounts;
        IEigenAirdrop(address(eigenAirdrop)).initialize(        
        msg.sender,
        airdropAddresses.REWARDS_MULTISIG,
        airdropAddresses.EIGEN_TOKEN,
        airdropAddresses.RESTAKING_STRATEGY,
        airdropAddresses.STRATEGY_MANAGER_ADDRESS,
        airdropDeadline,
        userAmounts);
    }
}
