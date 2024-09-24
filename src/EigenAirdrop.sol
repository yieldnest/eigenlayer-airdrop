// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct UserPoints {
    address userAddress;
    uint256 accumulatedPoints;
}

contract EigenAirdrop {
    mapping(address userAddress => uint256 points) public eigenAmounts;
    mapping(address userAddress => bool claimed) public airdropClaimed;
    uint256 public totalPoints;

    address public multiSig;
    uint256 public tokensPerPoint;
    IERC20 internal _rewardToken;

    event AirdropClaimed(address user, uint256 amount);

    constructor(address _multiSig, address _rewardERC20, UserPoints[] memory _userPoints) {
        multiSig = _multiSig;
        _rewardToken = IERC20(_rewardERC20);

        uint256 initialMultiSigBalance = _rewardToken.balanceOf(_multiSig);

        for (uint256 i; i < _userPoints.length; i++) {
            totalPoints += _userPoints[i].accumulatedPoints;
            eigenAmounts[_userPoints[i].userAddress] = _userPoints[i].accumulatedPoints;
        }

        tokensPerPoint = initialMultiSigBalance / totalPoints;

        require(tokensPerPoint != 0, "no airdrop");
    }

    function claim() external returns (uint256 _amountClaimed) {
        require(!airdropClaimed[msg.sender], "Ardrop already claimed.");
        _amountClaimed = eigenAmounts[msg.sender] * tokensPerPoint;
        _rewardToken.transferFrom(multiSig, msg.sender, _amountClaimed);
        airdropClaimed[msg.sender] = true;
        emit AirdropClaimed(msg.sender, _amountClaimed);
    }
}
