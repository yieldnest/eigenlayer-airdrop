// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25 <0.9.0;

import { BaseData } from "./BaseData.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { console } from "forge-std/console.sol";

struct EigenPoints {
    address addr;
    uint256 points;
}

contract BaseScript is BaseData {
    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant _SALT = bytes32("ynETH@v0.0.1");

    Data public data;
    uint256 public initialSafeBalance;
    EigenPoints[] public eigenPoints;

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

    function _loadInput(string memory _path) internal {
        string memory path = string(abi.encodePacked(vm.projectRoot(), "/", _path));
        string memory json = vm.readFile(path);

        bytes memory parsedEigenPoints = vm.parseJson(json, ".eigenPoints");
        EigenPoints[] memory ePoints = abi.decode(parsedEigenPoints, (EigenPoints[]));
        uint256 totalYnETHHolderEigenPoints = vm.parseJsonUint(json, ".totalYnETHHolderEigenPoints");

        delete eigenPoints;

        uint256 totalPoints;
        for (uint256 i; i < ePoints.length; i++) {
            eigenPoints.push(ePoints[i]);
            totalPoints += ePoints[i].points;
        }

        console.log("Total Parsed Eigen Points: ", totalPoints);
        console.log("Total Input Eigen Points: ", totalYnETHHolderEigenPoints);

        // if (totalPoints != totalYnETHHolderEigenPoints) {
        //     revert InvalidInput();
        // }
    }

    function getDeploymentFile() internal virtual view returns (string memory) {
        string memory root = vm.projectRoot();
        return string.concat(root, "/deployments/ynETH-", vm.toString(block.chainid), ".json");
    }

}
