// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity ^0.8.24;

import { Script } from "forge-std/Script.sol";

contract BaseData is Script {
        struct AirdropAddresses {
        address REWARDS_MULTISIG;
        address EIGEN_TOKEN;
        address B_EIGEN_TOKEN;
        address STRATEGY_MANAGER_ADDRESS;
        address RESTAKING_STRATEGY;
    }

    struct ChainIds {
        uint256 mainnet;
        uint256 holeksy;
    }

    mapping(uint256 => AirdropAddresses) public addresses;

    ChainIds public chainIds = ChainIds({
        mainnet: 1,
        holeksy: 17000
    });
    
    constructor() {
        addresses[chainIds.mainnet] = AirdropAddresses({
            REWARDS_MULTISIG: 0xCCB2FEB7d8e081dcedFe1CFbefC9d46Eb383E389,
            EIGEN_TOKEN: 0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83,
            B_EIGEN_TOKEN: 0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83,
            STRATEGY_MANAGER_ADDRESS: 0xdfB5f6CE42aAA7830E94ECFCcAd411beF4d4D5b6,  // double check this got this from the protocol addresses
            RESTAKING_STRATEGY: 0xaCB55C530Acdb2849e6d4f36992Cd8c9D50ED8F7
        });
    }

    function getAddresses(uint256 chainId) external view returns (AirdropAddresses memory) {
        return addresses[chainId];
    }

    function isSupportedChainId(uint256 chainId) external view returns (bool) {
        return chainId == chainIds.mainnet || chainId == chainIds.holeksy;
    }
}