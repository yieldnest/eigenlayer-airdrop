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
        uint256 anvil;
    }

    mapping(uint256 chainId => Data data) private __data;

    ChainIds public chainIds = ChainIds({ mainnet: 1, anvil: 31_337 });

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
    }

    function getData(uint256 chainId) internal view returns (Data memory) {
        return __data[chainId];
    }

    function isSupportedChainId(uint256 chainId) internal view returns (bool) {
        return chainId == chainIds.mainnet || chainId == chainIds.anvil;
    }
}
