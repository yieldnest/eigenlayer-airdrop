// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { DelegationManager } from "eigenlayer-contracts/core/DelegationManager.sol";
import { StrategyManager } from "eigenlayer-contracts/core/StrategyManager.sol";

import { IStrategy } from "eigenlayer-contracts/interfaces/IStrategy.sol";

import { BackingEigen } from "eigenlayer-contracts/token/BackingEigen.sol";
import { Eigen } from "eigenlayer-contracts/token/Eigen.sol";
import { Test } from "forge-std/Test.sol";

contract BaseTest is Test {
    error RPCNotSet();

    Eigen internal constant EIGEN = Eigen(0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83);
    address internal constant YNSAFE = 0xCCB2FEB7d8e081dcedFe1CFbefC9d46Eb383E389;
    StrategyManager internal constant STRATEGY_MANAGER =
        StrategyManager(0x858646372CC42E1A627fcE94aa7A7033e7CF075A);
    DelegationManager internal constant DELEGATION_MANAGER =
        DelegationManager(0x39053D51B77DC0d36036Fc1fCc8Cb819df8Ef37A);
    IStrategy internal constant STRATEGY = IStrategy(0xaCB55C530Acdb2849e6d4f36992Cd8c9D50ED8F7);
    address OPERATOR = 0xa83e07353A9ED2aF88e7281a2fA7719c01356D8e;

    BackingEigen internal constant BEIGEN = BackingEigen(0x83E9115d334D248Ce39a6f36144aEaB5b3456e75);

    uint256 internal constant INITIAL_BALANCE = 124_459_120_634_647_860_000_000;

    function setUp() public virtual {
        string memory rpc = vm.envOr("MAINNET_RPC_URL", string(""));
        if (bytes(rpc).length == 0) {
            revert RPCNotSet();
        }

        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_817_714 });
    }
}
