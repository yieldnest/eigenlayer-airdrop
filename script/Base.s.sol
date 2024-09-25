// SPDX-License-Identifier: MIT
pragma solidity >=0.8.25 <0.9.0;

import { BaseData } from "./BaseData.s.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct EigenAmounts {
    address addr;
    string percentage;
    uint256 points;
}

contract BaseScript is BaseData {

    /// @dev Needed for the deterministic deployments.
    bytes32 internal constant ZERO_SALT = bytes32(0);

    BaseData public baseData = new BaseData();
    AirdropAddresses public airdropAddresses;
    EigenAmounts[] public eigenAmounts;

    uint256 public multisigBalance;

    constructor() {
        require(baseData.isSupportedChainId(block.chainid));
        airdropAddresses = baseData.getAddresses(uint256(block.chainid));
        multisigBalance = IERC20(airdropAddresses.EIGEN_TOKEN).balanceOf(airdropAddresses.REWARDS_MULTISIG);
        require(multisigBalance != 0, "No Airdrop");
    }

    function _loadEigenAmounts(string memory _path) internal {
        string memory path = string(abi.encodePacked(vm.projectRoot(), "/", _path));
        string memory json = vm.readFile(path);
        bytes memory data = vm.parseJson(json);

        EigenAmounts[] memory _eigenAmounts = abi.decode(data, (EigenAmounts[]));

        this.loadEigenAmounts(_eigenAmounts);
    }

    /**
     * @dev this function is required to load the JSON input struct into storage until that feature is added to
     * foundry
     */
    function loadEigenAmounts(EigenAmounts[] calldata _eigenAmounts) external {
        delete eigenAmounts;
        for (uint256 i; i < _eigenAmounts.length; i++) {
            eigenAmounts.push(_eigenAmounts[i]);
        }
    }
}
