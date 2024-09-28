// SPDX-License-Identifier: BSD 3-Clause License
pragma solidity >=0.8.25 <0.9.0;

import { Script } from "forge-std/Script.sol";

contract BaseData is Script {
    struct Data {
        address airdropOwner;
        address proxyAdmin;
        address rewardsSafe;
        address eigenToken;
        address bEigenToken;
        address strategyManager;
        address strategy;
    }

    struct ChainIds {
        uint256 mainnet;
        uint256 holesky;
        uint256 anvil;
    }

    mapping(uint256 chainId => Data data) private __data;

    ChainIds public chainIds = ChainIds({ mainnet: 1, holesky: 17_000, anvil: 31_337 });

    address private TEMP_AIRDROP_OWNER;
    address private TEMP_PROXY_CONTROLLER;

    function setUp() public virtual {
        TEMP_AIRDROP_OWNER = makeAddr("airdrop-owner");
        TEMP_PROXY_CONTROLLER = makeAddr("proxy-controller");

        __data[chainIds.mainnet] = Data({
            airdropOwner: TEMP_AIRDROP_OWNER,
            proxyAdmin: TEMP_PROXY_CONTROLLER,
            rewardsSafe: 0xCCB2FEB7d8e081dcedFe1CFbefC9d46Eb383E389,
            eigenToken: 0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83,
            bEigenToken: 0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83,
            strategyManager: 0x858646372CC42E1A627fcE94aa7A7033e7CF075A,
            strategy: 0xaCB55C530Acdb2849e6d4f36992Cd8c9D50ED8F7
        });

        __data[chainIds.holesky] = Data({
            airdropOwner: TEMP_AIRDROP_OWNER,
            proxyAdmin: TEMP_PROXY_CONTROLLER,
            rewardsSafe: 0x8BC702B8708d55F24Ec26ca8f151eC7a1B2A6441,
            eigenToken: 0x3B78576F7D6837500bA3De27A60c7f594934027E,
            bEigenToken: 0x275cCf9Be51f4a6C94aBa6114cdf2a4c45B9cb27,
            strategyManager: 0xdfB5f6CE42aAA7830E94ECFCcAd411beF4d4D5b6,
            strategy: 0x43252609bff8a13dFe5e057097f2f45A24387a84
        });
    }

    function getData(uint256 chainId) internal view returns (Data memory) {
        return __data[chainId];
    }

    function isSupportedChainId(uint256 chainId) internal view returns (bool) {
        return chainId == chainIds.mainnet;
    }
}
