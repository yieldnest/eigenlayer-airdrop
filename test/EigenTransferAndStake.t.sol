// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25 <0.9.0;

import { Test, console } from "forge-std/Test.sol";
import { Eigen } from "eigenlayer-contracts/token/Eigen.sol";

contract EigenTransferAndStakeTest is Test {
    Eigen internal eigenToken;
    address internal ynSafe;

    uint256 mainnetFork;

    function setUp() public virtual {
        eigenToken = Eigen(0xec53bF9167f50cDEB3Ae105f56099aaaB9061F83);
        ynSafe = 0xCCB2FEB7d8e081dcedFe1CFbefC9d46Eb383E389;

        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        if (bytes(alchemyApiKey).length == 0) {
            revert("API_KEY_ALCHEMY is not set");
        }

        mainnetFork = vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 20_817_714 });
    }

    function test_Balance() external view {
        uint256 expected = 124_459_120_634_647_860_000_000;
        uint256 actual = eigenToken.balanceOf(ynSafe);

        assertEq(actual, expected, "Balance");
    }
}
