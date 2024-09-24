// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import {
    IStrategy,
    IStrategyManager
} from "eigenlayer-contracts/interfaces/IStrategyManager.sol";
import { Eigen } from "eigenlayer-contracts/token/Eigen.sol";
import { Test } from "forge-std/Test.sol";

contract BaseTest is Test {
    error AlchemyAPIKeyNotSet();

    Eigen internal constant EIGEN = Eigen(0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83);
    address internal constant YNSAFE = 0xCCB2FEB7d8e081dcedFe1CFbefC9d46Eb383E389;
    IStrategyManager internal constant STRATEGY_MANAGER =
        IStrategyManager(0x858646372CC42E1A627fcE94aa7A7033e7CF075A);
    IStrategy internal constant STRATEGY = IStrategy(0xaCB55C530Acdb2849e6d4f36992Cd8c9D50ED8F7);

    uint256 internal constant INITIAL_BALANCE = 124_459_120_634_647_860_000_000;

    function setUp() public virtual {
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        if (bytes(alchemyApiKey).length == 0) {
            revert AlchemyAPIKeyNotSet();
        }

        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_817_714 });
    }
}
