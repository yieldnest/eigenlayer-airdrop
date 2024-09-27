// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25 <0.9.0;

import { BaseData } from "./BaseData.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { console } from "forge-std/console.sol";

import { UserAmount } from "../src/IEigenAirdrop.sol";

struct EigenTokens {
    address addr;
    uint256 tokens;
}

contract BaseScript is BaseData {
    Data public data;
    uint256 public initialSafeBalance;

    EigenTokens[] public eigenTokens;
    UserAmount[] public userAmounts;

    uint256 public totalPoints;
    uint256 public totalAmount;

    error ChainIdNotSupported(uint256 chainId);
    error InvalidInput();
    error NoAirdrop();

    function setUp() public override {
        super.setUp();

        if (!isSupportedChainId(block.chainid)) {
            revert ChainIdNotSupported(block.chainid);
        }

        data = getData(block.chainid);

        initialSafeBalance = IERC20(data.eigenToken).balanceOf(data.rewardsSafe);
        if (initialSafeBalance == 0) {
            revert NoAirdrop();
        }
    }

    function _calculateUserAmounts() internal {
        UserAmount memory tempUserAmount;
        for (uint256 i; i < eigenTokens.length; i++) {
            if (eigenTokens[i].points == 0) {
                continue;
            }
            tempUserAmount.user = eigenTokens[i].addr;
            // tempUserAmount.amount = Math.mulDiv(eigenTokens[i].points, initialSafeBalance, totalPoints);
            tempUserAmount.amount = eigenToken[i].tokens;

            userAmounts.push(tempUserAmount);
            totalAmount += tempUserAmount.amount;
        }

        if (totalAmount > initialSafeBalance) {
            revert InvalidInput();
        }
        if (userAmounts.length == 0) {
            revert InvalidInput();
        }
    }

    function _loadInput(string memory _path) internal {
        string memory path = string(abi.encodePacked(vm.projectRoot(), "/", _path));
        string memory json = vm.readFile(path);

        bytes memory parsedEigenTokens = vm.parseJson(json, ".tokens");
        EigenTokens[] memory ePoints = abi.decode(parsedEigenTokens, (EigenTokens[]));

        delete eigenTokens;

        totalPoints = 0;
        for (uint256 i; i < ePoints.length; i++) {
            eigenTokens.push(ePoints[i]);
            totalPoints += ePoints[i].points;
        }

        _calculateUserAmounts();
    }

    function _getDeploymentFile() internal view virtual returns (string memory) {
        string memory root = vm.projectRoot();
        return string.concat(root, "/deployments/ynETH-", vm.toString(block.chainid), ".json");
    }
}
